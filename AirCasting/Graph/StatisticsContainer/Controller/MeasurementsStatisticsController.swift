// Created by Lunar on 06/07/2021.
//

import Foundation

class MeasurementsStatisticsController: MeasurementsStatisticsInput {
    private let uuid = UUID().uuidString
    weak var output: MeasurementsStatisticsOutput?
    private let dataSource: MeasurementsStatisticsDataSource
    private let calculator: StatisticsCalculator
    private let scheduledTimer: ScheduledTimerSettable
    private let desiredStats: [MeasurementStatistics.Statistic]
    private var timerCancellable: Cancellable?
    
    init(dataSource: MeasurementsStatisticsDataSource,
         calculator: StatisticsCalculator,
         scheduledTimer: ScheduledTimerSettable,
         desiredStats: [MeasurementStatistics.Statistic]) {
        self.dataSource = dataSource
        self.calculator = calculator
        self.scheduledTimer = scheduledTimer
        self.desiredStats = desiredStats
        timerCancellable = scheduledTimer.setupRepeatingTimer(for: 1.0, block: { [weak self] in
            self?.computeStatistics()
        })
    }
    
    func computeStatistics() {
        output?.statisticsDidChange(to: calculateStats())
    }
    
    private func calculateStats() -> [MeasurementStatistics.StatisticItem] {
        desiredStats.map { stat -> MeasurementStatistics.StatisticItem in
            let dataSet = stat == .latest ? dataSource.allMeasurements : dataSource.visibleMeasurements
            let value = calculator.calculateValue(for: stat, from: dataSet)
            return .init(stat: stat, value: value)
        }
    }
}
