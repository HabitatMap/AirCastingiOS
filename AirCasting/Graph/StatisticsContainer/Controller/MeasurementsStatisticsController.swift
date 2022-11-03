// Created by Lunar on 06/07/2021.
//

import Foundation
import Resolver

class MeasurementsStatisticsController: MeasurementsStatisticsInput {
    weak var output: MeasurementsStatisticsOutput?
    var continuousModeEnabled: Bool = false {
        didSet {
            if continuousModeEnabled && computeStatisticsInterval != nil {
                Log.verbose("Continuous mode enabled, adding timer")
                timerCancellable = scheduledTimer.setupRepeatingTimer(for: computeStatisticsInterval!, block: { [weak self] in
                    self?.computeStatistics()
                })
            } else if !continuousModeEnabled {
                Log.verbose("Continuous mode disabled, cancelling timer")
                timerCancellable = nil
            }
        }
    }
    @Injected private var scheduledTimer: ScheduledTimerSettable
    private var dataSource: MeasurementsStatisticsDataSource
    private let calculator: StatisticsCalculator
    private let desiredStats: [MeasurementStatistics.Statistic]
    private var timerCancellable: Cancellable?
    private let computeStatisticsInterval: Double?
    
    init(dataSource: MeasurementsStatisticsDataSource,
         calculator: StatisticsCalculator,
         desiredStats: [MeasurementStatistics.Statistic],
         computeStatisticsInterval: Double?) {
        self.dataSource = dataSource
        self.calculator = calculator
        self.desiredStats = desiredStats
        self.computeStatisticsInterval = computeStatisticsInterval
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
            return .init(stat: stat, value: value)
        }
    }
}
