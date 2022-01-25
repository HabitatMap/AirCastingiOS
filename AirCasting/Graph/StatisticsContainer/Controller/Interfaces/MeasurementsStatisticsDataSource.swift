// Created by Lunar on 06/07/2021.
//

import Foundation

protocol MeasurementsStatisticsDataSource {
    var onForceReload: (() -> Void)? { get set }
    var allMeasurements: [MeasurementStatistics.Measurement] { get }
    var visibleMeasurements: [MeasurementStatistics.Measurement] { get }
    var measurementsType: MeasurementStatistics.StreamType { get }
}
