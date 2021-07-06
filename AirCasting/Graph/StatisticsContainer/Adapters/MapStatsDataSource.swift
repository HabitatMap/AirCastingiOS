// Created by Lunar on 06/07/2021.
//

import Foundation

class MapStatsDataSource: MeasurementsStatisticsDataSource {
    let stream: MeasurementStreamEntity
    
    var visiblePathPoints: [PathPoint]
    
    init(stream: MeasurementStreamEntity) {
        self.stream = stream
        self.visiblePathPoints = []
    }
    
    var allMeasurements: [MeasurementStatistics.Measurement] {
        stream.allMeasurements?.map {
            return MeasurementStatistics.Measurement(measurementTime: $0.time, value: $0.value)
        } ?? []
    }
    
    var visibleMeasurements: [MeasurementStatistics.Measurement] {
        let visible = visiblePathPoints.map { MeasurementStatistics.Measurement(measurementTime: $0.measurementTime, value: $0.measurement) }
        // In case there are no visible data items let's fallback to showing data for all of them.
        guard visible.count > 0 else { return allMeasurements }
        return visible
    }
}
