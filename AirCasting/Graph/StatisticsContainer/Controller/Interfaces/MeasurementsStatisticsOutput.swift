// Created by Lunar on 06/07/2021.
//

import Foundation

protocol MeasurementsStatisticsOutput: AnyObject {
    func statisticsDidChange(to: [MeasurementStatistics.StatisticItem])
}
