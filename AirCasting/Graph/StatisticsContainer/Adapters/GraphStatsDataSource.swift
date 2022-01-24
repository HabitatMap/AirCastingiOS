// Created by Lunar on 06/07/2021.
//

import Foundation
import Gzip

class GraphStatsDataSource: MeasurementsStatisticsDataSource, ObservableObject {
    var stream: MeasurementStreamEntity? {
        didSet {
            onForceReload?()
        }
    }
    var onForceReload: (() -> Void)?
    var dateRange: ClosedRange<Date> = DateBuilder.distantPast()...DateBuilder.distantFuture()
    
    var allMeasurements: [MeasurementStatistics.Measurement] {
        return stream?.allMeasurements?.getStatistics() ?? []
    }
    
    var visibleMeasurements: [MeasurementStatistics.Measurement] {
        let filtered = allMeasurements.filter { dateRange.contains($0.measurementTime) }
        // In case there are no visible data items let's fallback to showing data for all of them.
        guard filtered.count > 0 else { return allMeasurements }
        return filtered
    }
}
