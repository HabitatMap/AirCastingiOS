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
    
    @ObservedObject var stream: MeasurementStreamEntity
    @ObservedObject var thresholds: SensorThreshold
    private var action: OnChange?
    
    var isAutozoomEnabled: Bool
    let simplifiedGraphEntryThreshold = 1000
    
    init(stream: MeasurementStreamEntity, thresholds: SensorThreshold, isAutozoomEnabled: Bool) {
        self.stream = stream
        self.thresholds = thresholds
        self.isAutozoomEnabled = isAutozoomEnabled
    }
    
    func onDateRangeChange(perform action: @escaping OnChange) -> Self {
        var newGraph = self
        newGraph.action = action
        return newGraph
    }
    
    func makeUIView(context: Context) -> AirCastingGraph {
        let uiView = AirCastingGraph(onDateRangeChange: { newRange in
            action?(newRange)
        })
        try? uiView.updateWithThreshold(thresholdValues: thresholds.rawThresholdsBinding.wrappedValue)
        let entries = stream.allMeasurements?.compactMap({ measurement -> ChartDataEntry? in
            let timeInterval = Double(measurement.time.timeIntervalSince1970)
            let chartDataEntry = ChartDataEntry(x: timeInterval, y: measurement.value)
            return chartDataEntry
        }) ?? []
        let allLimitLines = getLimitLines()
        uiView.limitLines = allLimitLines
        simplifyGraphline(entries: entries, uiView: uiView)
        context.coordinator.numberOfMeasurements = stream.allMeasurements?.count ?? 0
        context.coordinator.currentThreshold = ThresholdWitness(sensorThreshold: thresholds)
        return uiView
    }
    
    func updateUIView(_ uiView: AirCastingGraph, context: Context) {
        let thresholdWitness = ThresholdWitness(sensorThreshold: self.thresholds)
        
        if context.coordinator.currentThreshold != thresholdWitness ||
            context.coordinator.numberOfMeasurements != stream.allMeasurements?.count {
            
            try? uiView.updateWithThreshold(thresholdValues: thresholds.rawThresholdsBinding.wrappedValue)
            let entries = stream.allMeasurements?.compactMap({ measurement -> ChartDataEntry? in
                let timeInterval = Double(measurement.time.timeIntervalSince1970)
                let chartDataEntry = ChartDataEntry(x: timeInterval, y: measurement.value)
                return chartDataEntry
            }) ?? []
            let allLimitLines = getLimitLines()
            uiView.limitLines = allLimitLines
            simplifyGraphline(entries: entries, uiView: uiView)
            
            context.coordinator.currentThreshold = ThresholdWitness(sensorThreshold: thresholds)
            context.coordinator.numberOfMeasurements = stream.allMeasurements?.count ?? 0
        }
    }
    
    private func simplifyGraphline(entries: [ChartDataEntry], uiView: AirCastingGraph) {
        
        let startTime = uiView.lineChartView.lowestVisibleX
        let endTime = uiView.lineChartView.highestVisibleX
        
        let counter = entries.filter({ $0.x >= startTime && $0.x <= endTime }).count
        
        if counter > simplifiedGraphEntryThreshold {
            let simplifiedPoints = SwiftSimplify.simplify(entries,
                                                          tolerance: 0.000000001,
                                                          highestQuality: true)
            uiView.updateWithEntries(entries: simplifiedPoints, isAutozoomEnabled: isAutozoomEnabled)
            print("Simplified \(entries.count) to \(simplifiedPoints.count)")
        } else {
            uiView.updateWithEntries(entries: entries, isAutozoomEnabled: isAutozoomEnabled)
        }
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
        let points = getMidnightsPoints(startingDate: stream.allMeasurements?.first?.time ?? Date().currentUTCTimeZoneDate, endingDate: stream.allMeasurements?.last?.time ?? Date().currentUTCTimeZoneDate)
        
        return points.map { point in
            let line = ChartLimitLine(limit: point)
            line.lineColor = UIColor.aircastingDarkGray
            line.lineWidth = 0.7
            line.lineDashLengths = [5]
            line.lineDashPhase = CGFloat(2)
            return line
        }
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate {

        var parent: Graph!
        var numberOfMeasurements: Int?
        var currentThreshold: ThresholdWitness?
        
        init(_ parent: Graph) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
