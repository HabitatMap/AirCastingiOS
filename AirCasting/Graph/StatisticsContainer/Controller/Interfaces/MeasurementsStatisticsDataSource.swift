// Created by Lunar on 06/07/2021.
//

import Foundation

protocol MeasurementsStatisticsDataSource: AnyObject {
    var onForceReload: (() -> Void)? { get set }
    var allMeasurements: [MeasurementStatistics.Measurement] { get }
    var visibleMeasurements: [MeasurementStatistics.Measurement] { get }
}
