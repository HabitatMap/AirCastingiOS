// Created by Lunar on 28/02/2022.
//

import Foundation
import SwiftUI

class SearchAndFollowChartViewModel: ObservableObject {
    
    struct ChartMeasurement {
        let value: Double
        let time: Date
    }
    
    struct ChartDot {
        let xPosition: Double
        let value: Double
        let color: Color
    }
    
    @Published var entries: [ChartDot] = []
    
    func generateEntries(with measurements: [ChartMeasurement], thresholds: ThresholdsValue, using sensor: ChartMeasurementsFilter) -> (Date?, Date?) {
        var times: [Date] = []
        var buffer: [ChartMeasurement] = []
        var expectedNumberOfEntries = 9
        var xPosition = expectedNumberOfEntries - 1
        clearEntries()
        
        let updatedMeasurements = sensor.filter(measurements: measurements)
        
        for measurement in updatedMeasurements.reversed() {
            if entries.count >= expectedNumberOfEntries {
                break
            }
            
            if buffer.isEmpty || hourIsAlreadyPresent(in: buffer.map({ $0.time }), date: measurement.time) {
                buffer.append(measurement)
                continue
            }
            
            addAverage(for: buffer, atPosition: xPosition, times: &times, thresholds: thresholds)
            
            guard let lastMeasurement = buffer.last else { assertionFailure(); return (nil, nil) }
            
            let hoursDifference = hoursDifference(between: measurement, and: lastMeasurement)
            xPosition -= hoursDifference
            expectedNumberOfEntries -= (hoursDifference - 1)
            
            buffer = [measurement]
        }
        
        if entries.count < expectedNumberOfEntries && !buffer.isEmpty {
            addAverage(for: buffer, atPosition: xPosition, times: &times, thresholds: thresholds)
        }
        
        entries.reverse()
        
        guard let startTime = times.min(), let endTime = times.max(), !entries.isEmpty else { return (startTime: nil, endTime: nil) }
        
        // This is to handle the situation when there is no measurement in the first hour of 9h window
        let gapOnTheLeft = entries.first!.xPosition
        let emptyHours = gapOnTheLeft*60*60
        
        return (startTime: startTime - emptyHours, endTime: endTime)
    }
    
    private func clearEntries() { entries = [] }
    
    private func hoursDifference(between currentMeasurement: ChartMeasurement, and lastMeasurement: ChartMeasurement) -> Int {
        let nowComponent = Calendar.current.component(.hour, from: currentMeasurement.time)
        let lastComponent = Calendar.current.component(.hour, from: lastMeasurement.time)
        
        // last component is smaller from now component when there is midnight between them
        let difference = lastComponent < nowComponent ? 24 - nowComponent + lastComponent : lastComponent - nowComponent
        return difference
    }
    
    private func addAverage(for buffer: [ChartMeasurement], atPosition xPosition: Int, times: inout [Date], thresholds: ThresholdsValue) {
        guard !buffer.isEmpty else { return }
        var average = round((buffer.map { $0.value }.reduce(0, +)) / Double(buffer.count))
        
        if average == -0 { average = 0 }
        
        times.append(buffer.last!.time.roundedUpToHour)
        
        entries.append(ChartDot(xPosition: Double(xPosition), value: Double(average), color: thresholds.colorFor(value: average)))
    }
    
    private func hourIsAlreadyPresent(in times: [Date], date: Date) -> Bool {
        let nowComponent = Calendar.current.component(.hour, from: date)
        let hoursAlreadyPresent = times.map { Calendar.current.component(.hour, from: $0) }
        return hoursAlreadyPresent.contains(nowComponent)
    }
}
