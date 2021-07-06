// Created by Lunar on 06/07/2021.
//

import Foundation

class SwapableMeasurementsStatsOutput: MeasurementsStatisticsOutput {
    var output: MeasurementsStatisticsOutput?
    
    func statisticsDidChange(to stats: [MeasurementStatistics.StatisticItem]) {
        output?.statisticsDidChange(to: stats)
    }
}
