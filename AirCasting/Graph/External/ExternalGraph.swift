import SwiftUI
import Charts
import Resolver

struct ExternalGraph: UIViewRepresentable {
    typealias UIViewType = AirCastingGraph
    typealias OnChange = (ClosedRange<Date>) -> Void
    
    @InjectedObject private var userSettings: UserSettings
    @ObservedObject var stream: MeasurementStreamEntity
    @ObservedObject var thresholds: SensorThreshold
    private var rangeChangeAction: OnChange?
    
    var isAutozoomEnabled: Bool
    let simplifiedGraphEntryThreshold = 1000
    
    init(stream: MeasurementStreamEntity, thresholds: SensorThreshold, isAutozoomEnabled: Bool) {
        self.stream = stream
        self.thresholds = thresholds
        self.isAutozoomEnabled = isAutozoomEnabled
    }
    
    func onDateRangeChange(perform action: @escaping OnChange) -> Self {
        var newGraph = self
        newGraph.rangeChangeAction = action
        return newGraph
    }
    
    func makeUIView(context: Context) -> AirCastingGraph {
        let uiView = AirCastingGraph(onDateRangeChange: { newRange in
            rangeChangeAction?(newRange)
        })
        try? uiView.updateWithThreshold(thresholdValues: thresholds.rawThresholdsBinding.wrappedValue)

        let entries = stream.allMeasurements?.sorted(by: { $0.time < $1.time }).compactMap({ measurement -> ChartDataEntry? in
            let timeInterval = Double(measurement.time.timeIntervalSince1970)
            let chartDataEntry = ChartDataEntry(x: timeInterval, y: getValue(of: measurement))
            return chartDataEntry
        }) ?? []
        let allLimitLines = getLimitLines()
        uiView.limitLines = allLimitLines
        simplifyGraphline(entries: entries, uiView: uiView)
        
        context.coordinator.currentThreshold = ThresholdWitness(sensorThreshold: thresholds)
        context.coordinator.currentMeasurementsNumber = calculateVisiblePointsNumber(entries: entries, uiView: uiView)
        context.coordinator.entries = entries
        context.coordinator.lastMeasurementTime = stream.allMeasurements?.last?.time
        context.coordinator.stream = stream
        return uiView
    }
    
    func updateUIView(_ uiView: AirCastingGraph, context: Context) {
        let thresholdWitness = ThresholdWitness(sensorThreshold: self.thresholds)
        let counter: Int = calculateVisiblePointsNumber(entries: context.coordinator.entries!, uiView: uiView)
        let lastMeasurementTime = stream.allMeasurements?.last?.time
        
        if counter != context.coordinator.currentMeasurementsNumber {
            simplifyGraphline(entries: context.coordinator.entries!, uiView: uiView)
            context.coordinator.currentMeasurementsNumber = counter
        }
        
        guard context.coordinator.currentThreshold != thresholdWitness ||
                stream != context.coordinator.stream ||
                lastMeasurementTime != context.coordinator.lastMeasurementTime else { return }
        
        try? uiView.updateWithThreshold(thresholdValues: thresholds.rawThresholdsBinding.wrappedValue)
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
        context.coordinator.currentMeasurementsNumber = entries.count
        context.coordinator.lastMeasurementTime = stream.allMeasurements?.last?.time
        context.coordinator.stream = stream
    }
    
    private func simplifyGraphline(entries: [ChartDataEntry], uiView: AirCastingGraph) {
        let counter: Int = calculateVisiblePointsNumber(entries: entries, uiView: uiView)
        
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
    
    func calculateVisiblePointsNumber(entries: [ChartDataEntry], uiView: AirCastingGraph) -> Int {
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
            guard let previous = Calendar.current.nextDate(after: midnight,
                                                           matching: components,
                                                           matchingPolicy: Calendar.MatchingPolicy.previousTimePreservingSmallerComponents,
                                                           repeatedTimePolicy: Calendar.RepeatedTimePolicy.first,
                                                           direction: .backward) else { return [] }
            
            let previousTimeInterval = previous.currentUTCTimeZoneDate.timeIntervalSince1970
            midnightPoints.append(previousTimeInterval)
            midnight = previous
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
        
        var stream: MeasurementStreamEntity?
        var currentThreshold: ThresholdWitness?
        var currentMeasurementsNumber: Int?
        var entries: [ChartDataEntry]?
        var lastMeasurementTime: Date?
        var parent: ExternalGraph!
        
        init(_ parent: ExternalGraph) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
