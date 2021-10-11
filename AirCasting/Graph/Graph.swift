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
        AirCastingGraph(onDateRangeChange: { newRange in
            action?(newRange)
        })
    }
    
    func updateUIView(_ uiView: AirCastingGraph, context: Context) {
        try? uiView.updateWithThreshold(thresholdValues: thresholds.rawThresholdsBinding.wrappedValue)
  
        let entries = stream.allMeasurements?.compactMap({ measurement -> ChartDataEntry? in
            let timeInterval = Double(measurement.time.timeIntervalSince1970)
            let chartDataEntry = ChartDataEntry(x: timeInterval, y: measurement.value)
            return chartDataEntry
        }) ?? []
        let allLimitLines = getLimitLines()
        uiView.limitLines = allLimitLines
        simplifyGraphline(entries: entries, uiView: uiView)
    }
    
    private func simplifyGraphline(entries: [ChartDataEntry], uiView: AirCastingGraph) {
        
        var counter = 0
        let startTime = uiView.lineChartView.lowestVisibleX
        let endTime = uiView.lineChartView.highestVisibleX
        
        entries.forEach { entry in
            (entry.x >= startTime && entry.x <= endTime) ? counter += 1 : nil
        }
        
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
    
    func getMidnightsPoints(startingDate: Date) -> [Double] {
        let now = Date()
        var midnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: now)!
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: midnight)
        let firstMeasurementDate = startingDate
        var midnightPoints: [Double] = []
        
        while (midnight > firstMeasurementDate) {
            let previus = Calendar.current.nextDate(after: midnight,
                                                    matching: components,
                                                    matchingPolicy: Calendar.MatchingPolicy.previousTimePreservingSmallerComponents,
                                                    repeatedTimePolicy: Calendar.RepeatedTimePolicy.first,
                                                    direction: .backward)
            if let midnightPoint = previus?.timeIntervalSince1970 {
                midnightPoints.append(midnightPoint)
            }
            midnight = previus!
        }
        return midnightPoints
    }
    
    func getLimitLines() -> [ChartLimitLine] {
        let points = getMidnightsPoints(startingDate: stream.allMeasurements?.first?.time ?? Date())
        
        return points.map { point in
            let line = ChartLimitLine(limit: point)
            line.lineColor = UIColor.aircastingDarkGray
            line.lineWidth = 0.7
            line.lineDashLengths = [5]
            line.lineDashPhase = CGFloat(2)
            return line
        }
    }
}
