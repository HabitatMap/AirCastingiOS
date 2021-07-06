// Created by Lunar on 06/07/2021.
//

import Foundation

class MeasurementsStatisticsController: MeasurementsStatisticsInput {
    private let output: MeasurementsStatisticsOutput
    private let dataSource: MeasurementsStatisticsDataSource
    private let calculator: StatisticsCalculator
    private let desiredStats: [MeasurementStatistics.Statistic]
    
    init(output: MeasurementsStatisticsOutput,
         dataSource: MeasurementsStatisticsDataSource,
         calculator: StatisticsCalculator,
         desiredStats: [MeasurementStatistics.Statistic]) {
        self.output = output
        self.dataSource = dataSource
        self.calculator = calculator
        self.desiredStats = desiredStats
    }
    
    func visibleDataChanged() {
        output.statisticsDidChange(to: calculateStats())
    }
    
    private func calculateStats() -> [MeasurementStatistics.StatisticItem] {
        desiredStats.map { stat -> MeasurementStatistics.StatisticItem in
            let dataSet = stat == .latest ? dataSource.allMeasurements : dataSource.visibleMeasurements
            let value = calculator.calculateValue(for: stat, from: dataSet)
            return .init(stat: stat, value: value)
        }
    }
}
