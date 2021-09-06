// Created by Lunar on 06/07/2021.
//

import Foundation

protocol StatisticsCalculator {
    func calculateValue(for: MeasurementStatistics.Statistic, from: [MeasurementStatistics.Measurement]) -> Double
}
