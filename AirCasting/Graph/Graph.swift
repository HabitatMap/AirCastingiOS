//
//  PollutionGraph.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 15/01/2021.
//

import SwiftUI
import Charts
import SwiftSimplify
import CoreMedia
import Resolver

extension ChartDataEntry: Point2DRepresentable {
    public var xValue: Float {
        Float(self.x)
    }
    
    public var yValue: Float {
        Float(self.y)
    }
    
    public var cgPoint: CGPoint {
        .init(x: CGFloat(xValue), y: CGFloat(yValue))
    }
}

struct Graph: UIViewRepresentable {
    typealias UIViewType = AirCastingGraph
    typealias OnChange = (ClosedRange<Date>) -> Void
    typealias NoteAction = (Note) -> Void
    
    @InjectedObject private var userSettings: UserSettings
    @ObservedObject var stream: MeasurementStreamEntity
    @ObservedObject var thresholds: SensorThreshold
    private var rangeChangeAction: OnChange?
    private var noteAction: NoteAction?
    
    private var notesHandler: NotesHandler
    
    var isAutozoomEnabled: Bool
    let simplifiedGraphEntryThreshold = 1000
    private let formatter: ThresholdFormatter
    
    init(stream: MeasurementStreamEntity, thresholds: SensorThreshold, isAutozoomEnabled: Bool) {
        self.stream = stream
        self.thresholds = thresholds
        self.isAutozoomEnabled = isAutozoomEnabled
        self.notesHandler = Resolver.resolve(NotesHandler.self, args: stream.session.uuid)
        self.formatter = Resolver.resolve(ThresholdFormatter.self, args: thresholds)
    }
    
    func onDateRangeChange(perform action: @escaping OnChange) -> Self {
        var newGraph = self
        newGraph.rangeChangeAction = action
        return newGraph
    }
    
    func onNoteTap(perform action: @escaping NoteAction) -> Self {
        var newGraph = self
        newGraph.noteAction = action
        return newGraph
    }
    
    func makeUIView(context: Context) -> AirCastingGraph {
        let uiView = AirCastingGraph(onDateRangeChange: { newRange in
            rangeChangeAction?(newRange)
        })
        try? uiView.updateWithThreshold(thresholdValues: formatter.formattedNumerics())
        let entries = stream.allMeasurements?.sorted(by: { $0.time < $1.time }).compactMap({ measurement -> ChartDataEntry? in
            let timeInterval = Double(measurement.time.timeIntervalSince1970)
            let chartDataEntry = ChartDataEntry(x: timeInterval, y: getValue(of: measurement))
            return chartDataEntry
        }) ?? []
        let allLimitLines = getLimitLines()
        uiView.limitLines = allLimitLines
        simplifyGraphline(entries: entries, uiView: uiView)
        context.coordinator.totalNumberOfMeasurements = entries.count
        context.coordinator.currentThreshold = ThresholdWitness(sensorThreshold: thresholds)
        context.coordinator.currentMeasurementsNumber = calculateSeeingPointsNumber(entries: entries, uiView: uiView)
        context.coordinator.entries = entries
        context.coordinator.stream = stream
        refreshNotes(uiView)
        notesHandler.observer = {
            refreshNotes(uiView)
        }
        return uiView
    }
    
    func updateUIView(_ uiView: AirCastingGraph, context: Context) {
        // This code helps us to make graph faster and snappier
        // The -if- statement is executed on dormant and active sessions to ensure it updates graph line well
        // The -guard- code is executed only on active sessions and on data change events
        // (⊙_◎)
        let thresholdWitness = ThresholdWitness(sensorThreshold: self.thresholds)
        let counter: Int = calculateSeeingPointsNumber(entries: context.coordinator.entries!, uiView: uiView)
        
        if counter != context.coordinator.currentMeasurementsNumber {
            simplifyGraphline(entries: context.coordinator.entries!, uiView: uiView)
            context.coordinator.currentMeasurementsNumber = counter
        }
        
        guard context.coordinator.currentThreshold != thresholdWitness ||
                context.coordinator.totalNumberOfMeasurements != stream.allMeasurements?.count ||
                stream != context.coordinator.stream else { return }
        
        try? uiView.updateWithThreshold(thresholdValues: formatter.formattedNumerics())
        let allLimitLines = getLimitLines()
        uiView.limitLines = allLimitLines
        
        let entries = stream.allMeasurements?.sorted(by: { $0.time < $1.time }).compactMap({ measurement -> ChartDataEntry? in
            let timeInterval = Double(measurement.time.timeIntervalSince1970)
            let chartDataEntry = ChartDataEntry(x: timeInterval, y: getValue(of: measurement))
            return chartDataEntry
        }) ?? []
        
        simplifyGraphline(entries: entries, uiView: uiView)
        
        context.coordinator.entries = entries
        context.coordinator.currentThreshold = ThresholdWitness(sensorThreshold: thresholds)
        context.coordinator.totalNumberOfMeasurements = entries.count
        context.coordinator.currentMeasurementsNumber = entries.count
        context.coordinator.stream = stream
    }
    
    private func simplifyGraphline(entries: [ChartDataEntry], uiView: AirCastingGraph) {
        
        let counter: Int = calculateSeeingPointsNumber(entries: entries, uiView: uiView)
        
        guard counter > simplifiedGraphEntryThreshold else {
            uiView.updateWithEntries(entries: entries, isAutozoomEnabled: isAutozoomEnabled)
            return
        }
        let simplifiedPoints = AirCastingGraphSimplifier.simplify(points: entries,
                                                                  visibleElementsNumber: counter,
                                                                  thresholdLimit: simplifiedGraphEntryThreshold)
        uiView.updateWithEntries(entries: simplifiedPoints, isAutozoomEnabled: isAutozoomEnabled)
        Log.info("Simplified \(entries.count) to \(simplifiedPoints.count)")
    }
    
    private func refreshNotes(_ uiView: AirCastingGraph) {
        notesHandler.getNotes { notes in
            DispatchQueue.main.async {
                uiView.setupNotes(notes) { noteAction?($0) }
            }
        }
    }
    
    func calculateSeeingPointsNumber(entries: [ChartDataEntry], uiView: AirCastingGraph) -> Int {
        let startTime = uiView.lineChartView.lowestVisibleX
        let endTime = uiView.lineChartView.highestVisibleX
        
        let counter: Int = entries.filter({ $0.x >= startTime && $0.x <= endTime }).count
        return counter
    }
    
    func getMidnightsPoints(startingDate: Date, endingDate: Date) -> [Double] {
        let day = endingDate
        // [SMALL HACK] - By adding 2 day's to the lastMeasurement Date we are ensuring
        // that session which is currently recording will be able to show midnight line
        // or on any other session the midnight line will be considered well
        let twoDaysAhead = Calendar.current.date(byAdding: .day, value: 2, to: day)!
        var midnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: twoDaysAhead)!
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: midnight)
        let firstMeasurementDate = startingDate
        var midnightPoints: [Double] = []
        
        while (midnight > firstMeasurementDate) {
            let previous = Calendar.current.nextDate(after: midnight,
                                                    matching: components,
                                                    matchingPolicy: Calendar.MatchingPolicy.previousTimePreservingSmallerComponents,
                                                    repeatedTimePolicy: Calendar.RepeatedTimePolicy.first,
                                                     direction: .backward)
            
            if let midnightPoint = previous?.currentUTCTimeZoneDate.timeIntervalSince1970 {
                midnightPoints.append(midnightPoint)
            }
            midnight = previous!
        }
        return midnightPoints
    }
    
    func getLimitLines() -> [ChartLimitLine] {
        let points = getMidnightsPoints(startingDate: stream.allMeasurements?.first?.time ?? DateBuilder.getFakeUTCDate(), endingDate: stream.allMeasurements?.last?.time ?? DateBuilder.getFakeUTCDate())
        
        return points.map { point in
            let line = ChartLimitLine(limit: point)
            line.lineColor = UIColor.aircastingDarkGray
            line.lineWidth = 0.7
            line.lineDashLengths = [5]
            line.lineDashPhase = CGFloat(2)
            return line
        }
    }
    
    private func getValue(of measurement: MeasurementEntity) -> Double {
        measurement.measurementStream.isTemperature && userSettings.convertToCelsius ? TemperatureConverter.calculateCelsius(fahrenheit: measurement.value) : measurement.value
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate {

        var parent: Graph!
        var totalNumberOfMeasurements: Int?
        var currentThreshold: ThresholdWitness?
        var currentMeasurementsNumber: Int?
        var entries: [ChartDataEntry]?
        var stream: MeasurementStreamEntity?
        
        init(_ parent: Graph) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
