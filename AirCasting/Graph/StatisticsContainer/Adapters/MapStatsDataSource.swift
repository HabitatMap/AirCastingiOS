// Created by Lunar on 06/07/2021.
//

import Foundation

class MapStatsDataSource: MeasurementsStatisticsDataSource, ObservableObject {
    var stream: MeasurementStreamEntity? = nil {
        didSet {
            onForceReload?()
        }
    }
    
    var onForceReload: (() -> Void)?
    
    var visiblePathPoints: [PathPoint]
    
    init() {
        self.visiblePathPoints = []
    }
    
    var allMeasurements: [MeasurementStatistics.Measurement] {
        stream?.allMeasurements?.getStatistics() ?? []
    }
    
    var visibleMeasurements: [MeasurementStatistics.Measurement] {
        let visible = visiblePathPoints.map { MeasurementStatistics.Measurement(measurementTime: $0.measurementTime, value: $0.measurement) }
        // In case there are no visible data items let's fallback to showing data for all of them.
        guard visible.count > 0 else { return allMeasurements }
        return visible
    }
}
