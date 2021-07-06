// Created by Lunar on 06/07/2021.
//

import Foundation

protocol MeasurementsStatisticsDataSource {
    var allMeasurements: [MeasurementStatistics.Measurement] { get }
    var visibleMeasurements: [MeasurementStatistics.Measurement] { get }
}
