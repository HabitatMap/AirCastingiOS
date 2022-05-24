// Created by Lunar on 28/02/2022.
//

import Foundation
import SwiftUI

class SearchAndFollowChartViewModel: ObservableObject {
    struct ChartDot {
        let value: Double
        let color: Color
    }
    struct ChartMeasurement {
        let value: Double
        let time: Date
    }
    
    @Published var entries: [ChartDot] = []
    
    let numberOfEntries = 9
    
    func generateEntries(with measurements: [ChartMeasurement], thresholds: ThresholdsValue) -> (Date?, Date?) {
        var times: [Date] = []
        var buffer: [ChartMeasurement] = []
        entries = []
        
        for measurement in measurements.reversed() {
            if entries.count == 9 {
                break
            }
            
            if buffer.isEmpty || hourIsAlreadyPresent(in: buffer.map({ $0.time }), date: measurement.time) {
                buffer.append(measurement)
                continue
            }
            
            addAverage(for: buffer, times: &times, thresholds: thresholds)
            
            buffer = [measurement]
        }
        
        if entries.count < 9 && !buffer.isEmpty {
            addAverage(for: buffer, times: &times, thresholds: thresholds)
        }
        
        entries.reverse()
        return (startTime: times.min(), endTime: times.max())
    }
    
    func clearEntries() { entries = [] }
    
    private func addAverage(for buffer: [ChartMeasurement], times: inout [Date], thresholds: ThresholdsValue) {
        guard !buffer.isEmpty else { return }
        let average = (buffer.map { $0.value }.reduce(0, +)) / Double(buffer.count)
        
        times.append(buffer.last!.time.roundedUpToHour)
        entries.append(ChartDot(value: Double(average), color: thresholds.colorFor(value: average)))
    }
    
    private func hourIsAlreadyPresent(in times: [Date], date: Date) -> Bool {
        let nowComponent = Calendar.current.component(.hour, from: date)
        let hoursAlreadyPresent = times.map { Calendar.current.component(.hour, from: $0) }
        return hoursAlreadyPresent.contains(nowComponent)
    }
}
