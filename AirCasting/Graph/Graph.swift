//
//  PollutionGraph.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 15/01/2021.
//

import SwiftUI
import Charts
import SwiftSimplify

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
    
    @ObservedObject var stream: MeasurementStreamEntity
    @ObservedObject var thresholds: SensorThreshold
    var isAutozoomEnabled: Bool
    let simplifiedGraphEntryThreshold = 1000
    
    func makeUIView(context: Context) -> AirCastingGraph {
        AirCastingGraph()
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
        if entries.count > simplifiedGraphEntryThreshold {
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
