// Created by Lunar on 05/05/2021.
//

import Foundation
import Charts

final class ChartEntriesCreator {
    var entries: [ChartDataEntry] = []
    var stream: MeasurementStreamEntity
    lazy var timeUnit: Double = stream.session.type == .mobile ? 60 : 60*60
    lazy var lastMeasurementTime = {
        self.stream.lastMeasurementTime
    }
    
    init(stream: MeasurementStreamEntity) {
        self.stream = stream
    }
    
    func generateEntries() -> [ChartDataEntry] {
        guard let lastMeasurementTime = lastMeasurementTime() else {
            return []
        }
        
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
    
    private func averagedValue(_ intervalStart: Date, _ intervalEnd: Date) -> Double? {
        let measurements = stream.getMeasurementsFromTimeRange(intervalStart.roundedToSecond, intervalEnd.roundedToSecond)
        let values = measurements.map { $0.value}
        return values.isEmpty ? nil : round(values.reduce(0, +)/Double(values.count))
    }
}

extension Date {
    var roundedToSecond: Date {
        let date = self
        let diff = 1000000000 - Calendar.current.component(.nanosecond, from: date)
        return Calendar.current.date(byAdding: .nanosecond, value: diff, to: date)!
    }
}

