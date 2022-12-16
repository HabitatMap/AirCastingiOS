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
    
    var visiblePathPoints: [_MapView.PathPoint]
    
    init() {
        self.visiblePathPoints = []
    }
    
    var allMeasurements: [MeasurementStatistics.Measurement] {
        stream?.allMeasurements?.getStatistics() ?? []
    }
    
    var visibleMeasurements: [MeasurementStatistics.Measurement] {
        return stream?.allMeasurements?.getStatistics() ?? []
    }
}
