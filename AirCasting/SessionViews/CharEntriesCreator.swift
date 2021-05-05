// Created by Lunar on 05/05/2021.
//

import Foundation
import Charts

class ChartEntriesCreator {
//    var entries: [String: [Float]] = [:]
    var entries: [ChartDataEntry] = []
    var session: SessionEntity
    var stream: MeasurementStreamEntity
    var timeUnit: Double = 60 // FOR MOBILE, ADD FOR FIXED
    
    init(session: SessionEntity, stream: MeasurementStreamEntity) {
        self.session = session
        self.stream = stream
    }
    
    func generateEntries() -> [ChartDataEntry] {
        guard let lastMeasurementTime = stream.lastMeasurementTime else {
            return []
        }
        
        let sessionStartTime = session.startTime!
        
        let secondsFromFullMinute = Int(lastMeasurementTime.timeIntervalSince(sessionStartTime)) % Int(timeUnit)
        
        var intervalEnd = lastMeasurementTime - Double(secondsFromFullMinute)
        
        var intervalStart = intervalEnd - timeUnit
        
        for i in (0...8).reversed() {
            if (intervalStart < sessionStartTime) { break }
            entries.append(ChartDataEntry(x: Double(i), y: averagedValue(intervalStart, intervalEnd)))
            intervalEnd = intervalStart
            intervalStart = intervalEnd - timeUnit
        }
        
        return entries
    }
    
    func averagedValue(_ intervalStart: Date, _ intervalEnd: Date) -> Double {
        let measurements = stream.getMeasurementsFromTimeRange(intervalStart, intervalEnd)
        let values = measurements.map { $0.value}
        let sum = values.reduce(0, +)
        #warning("We should handle the situation when there are no measurements in a given minute, eg. because of the interruption. Not sure if it should be 0")
        let average = values.isEmpty ? 0 : sum/Double(values.count)
        print("average: \(average)")
        return average
    }
}
