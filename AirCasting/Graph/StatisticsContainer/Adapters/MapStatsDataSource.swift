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
    #warning("TODO: Implement calculating stats only for visible path points")
        // The implementation for visible points on map doesn't work as it should. That's why I'm commenting it out and we have  to fix it in another PR
//        let visible = visiblePathPoints.map { MeasurementStatistics.Measurement(measurementTime: $0.measurementTime, value: $0.measurement) }
//        // In case there are no visible data items let's fallback to showing data for all of them.
//        guard visible.count > 0 else { return allMeasurements }
//        return visible
        return stream?.allMeasurements?.getStatistics() ?? []
    }
}
