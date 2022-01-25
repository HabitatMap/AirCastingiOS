// Created by Lunar on 06/07/2021.
//

import Foundation

final class StatisticsContainerViewModel: StatisticsContainerViewModelable, MeasurementsStatisticsOutput {
    private let statsInput: MeasurementsStatisticsInput
    private var useCelsius: Bool
    
    init(statsInput: MeasurementsStatisticsInput, useCelsius: Bool = false) {
        self.statsInput = statsInput
        self.useCelsius = useCelsius
        statsInput.computeStatistics()
    }
    
    @Published var stats: [SingleStatViewModel] = []
    
    func adjustForNewData() {
        statsInput.computeStatistics()
    }
    
    func statisticsDidChange(to newStats: [MeasurementStatistics.StatisticItem]) {
        stats = newStats.map {
            SingleStatViewModel(id: getIdentifier(for: $0.stat),
                                title: getUILabel(for: $0.stat),
                                value: getValue($0),
                                presentationStyle: getPresentationStyle(for: $0.stat))
        }
    }
    
    private func getIdentifier(for stat: MeasurementStatistics.Statistic) -> Int {
        switch stat {
        case .average: return 1
        case .high: return 2
        case .latest: return 3
        }
    }
    
    private func getUILabel(for stat: MeasurementStatistics.Statistic) -> String {
        switch stat {
        case .average: return "Avg"
        case .high: return "Peak"
        case .latest: return "Now"
        }
    }
    
    private func getPresentationStyle(for stat: MeasurementStatistics.Statistic) -> SingleStatViewModel.PresentationStyle {
        switch stat {
        case .average, .high: return .standard
        case .latest: return .distinct
        }
    }
    
    private func getValue(_ stat: MeasurementStatistics.StatisticItem) -> Double {
        stat.type == .temperature && useCelsius ? TemperatureConverter.calculateCelsius(fahrenheit: stat.value) : stat.value
    }
}
