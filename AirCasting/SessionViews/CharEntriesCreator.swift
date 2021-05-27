// Created by Lunar on 05/05/2021.
//

import Foundation
import Charts

class ChartEntriesCreator {
//    var session: SessionEntity
    var stream: MeasurementStreamEntity
    lazy var timeUnit: Double = stream.session.type == .mobile ? 60 : 60*60 // FOR MOBILE, ADD FOR FIXED
    
    init(stream: MeasurementStreamEntity) {
//        self.session = session
        self.stream = stream
    }
    
    func generateEntries() -> [ChartDataEntry] {
        guard let lastMeasurementTime = stream.lastMeasurementTime else {
            return []
        }
        
        var entries: [ChartDataEntry] = []
        let sessionStartTime = stream.session.startTime!
        let secondsFromFullMinute = Int(lastMeasurementTime.timeIntervalSince(sessionStartTime)) % Int(timeUnit)
        var intervalEnd = lastMeasurementTime - Double(secondsFromFullMinute)
        var intervalStart = intervalEnd - timeUnit
        
        for i in (0...8).reversed() {
            if (intervalStart < sessionStartTime) { break }
            let average = averagedValue(intervalStart, intervalEnd)
            if let average = average {
                entries.append(ChartDataEntry(x: Double(i), y: average))
            }
            intervalEnd = intervalStart
            intervalStart = intervalEnd - timeUnit
        }
        
        return entries
    }
    
    func averagedValue(_ intervalStart: Date, _ intervalEnd: Date) -> Double? {
        let measurements = stream.getMeasurementsFromTimeRange(intervalStart, intervalEnd)
        let values = measurements.map { $0.value}
        return values.isEmpty ? nil : round(values.reduce(0, +)/Double(values.count))
    }
}
