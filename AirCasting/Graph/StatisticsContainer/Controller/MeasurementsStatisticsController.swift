// Created by Lunar on 06/07/2021.
//

import Foundation

class MeasurementsStatisticsController: MeasurementsStatisticsInput {
    weak var output: MeasurementsStatisticsOutput?
    private var dataSource: MeasurementsStatisticsDataSource
    private let calculator: StatisticsCalculator
    private let scheduledTimer: ScheduledTimerSettable
    private let desiredStats: [MeasurementStatistics.Statistic]
    private var timerCancellable: Cancellable?
    
    init(dataSource: MeasurementsStatisticsDataSource,
         calculator: StatisticsCalculator,
         scheduledTimer: ScheduledTimerSettable,
         desiredStats: [MeasurementStatistics.Statistic],
         computeStatisticsInterval: Double?) {
        self.dataSource = dataSource
        self.calculator = calculator
        self.scheduledTimer = scheduledTimer
        self.desiredStats = desiredStats
        if computeStatisticsInterval != nil {
            timerCancellable = scheduledTimer.setupRepeatingTimer(for: computeStatisticsInterval!, block: { [weak self] in
                 self?.computeStatistics()
            })
        }
        self.dataSource.onForceReload = { [weak self] in
            self?.computeStatistics()
        }
    }
    
    func computeStatistics() {
        output?.statisticsDidChange(to: calculateStats())
    }
    
    private func calculateStats() -> [MeasurementStatistics.StatisticItem] {
        desiredStats.map { stat -> MeasurementStatistics.StatisticItem in
            let dataSet = stat == .latest ? dataSource.allMeasurements : dataSource.visibleMeasurements
            let value = calculator.calculateValue(for: stat, from: dataSet)
            return .init(stat: stat, value: value, type: dataSource.measurementsType)
        }
    }
}
