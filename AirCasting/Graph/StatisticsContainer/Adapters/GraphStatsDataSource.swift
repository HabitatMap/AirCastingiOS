// Created by Lunar on 06/07/2021.
//

import Foundation

class GraphStatsDataSource: MeasurementsStatisticsDataSource {
    let stream: MeasurementStreamEntity
    
    var dateRange: ClosedRange<Date> = Date.distantPast...Date.distantFuture
    
    init(stream: MeasurementStreamEntity) {
        self.stream = stream
    }
    
    var allMeasurements: [MeasurementStatistics.Measurement] {
        stream.allMeasurements?.map {
            return MeasurementStatistics.Measurement(measurementTime: $0.time, value: $0.value)
        } ?? []
    }
    
    var visibleMeasurements: [MeasurementStatistics.Measurement] {
        let filtered = allMeasurements.filter { dateRange.contains($0.measurementTime) }
        // In case there are no visible data items let's fallback to showing data for all of them.
        guard filtered.count > 0 else { return allMeasurements }
        return filtered
    }
}
