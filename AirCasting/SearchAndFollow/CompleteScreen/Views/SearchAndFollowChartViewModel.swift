// Created by Lunar on 28/02/2022.
//

import Foundation
import SwiftUI

struct ChartMeasurement {
    let value: Double
    let time: Date
}

class SearchAndFollowChartViewModel: ObservableObject {
    struct ChartDot {
        let value: Double
        let color: Color
    }
    
    @Published var entries: [ChartDot] = []
    
    let numberOfEntries = 9
    
    func generateEntries(with measurements: [ChartMeasurement], thresholds: ThresholdsValue, basedOn sensor: ChartSensor) -> (Date?, Date?) {
        var times: [Date] = []
        var buffer: [ChartMeasurement] = []
        var updatedMeasurements = measurements
        
        sensor.clean(measurements: &updatedMeasurements)
        
        for measurement in updatedMeasurements.reversed() {
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
    
    private func addAverage(for buffer: [ChartMeasurement], times: inout [Date], thresholds: ThresholdsValue) {
        guard !buffer.isEmpty else { return }
        let average = round((buffer.map { $0.value }.reduce(0, +)) / Double(buffer.count))
        
        times.append(buffer.last!.time.roundedUpToHour)
        entries.append(ChartDot(value: Double(average), color: thresholds.colorFor(value: average)))
    }
    
    private func hourIsAlreadyPresent(in times: [Date], date: Date) -> Bool {
        let nowComponent = Calendar.current.component(.hour, from: date)
        let hoursAlreadyPresent = times.map { Calendar.current.component(.hour, from: $0) }
        return hoursAlreadyPresent.contains(nowComponent)
    }
}
