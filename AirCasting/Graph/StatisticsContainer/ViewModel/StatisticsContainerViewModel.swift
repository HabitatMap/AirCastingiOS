// Created by Lunar on 06/07/2021.
//

import Foundation

final class StatisticsContainerViewModel: StatisticsContainerViewModelable, MeasurementsStatisticsOutput {
    private let statsInput: MeasurementsStatisticsInput
    private let unit: String
    
    init(statsInput: MeasurementsStatisticsInput, unit: String) {
        self.statsInput = statsInput
        self.unit = unit
    }
    
    @Published var stats: [SingleStatViewModel] = []
    
    func adjustForNewData() {
        statsInput.visibleDataChanged()
    }
    
    func statisticsDidChange(to newStats: [MeasurementStatistics.StatisticItem]) {
        stats = newStats.map {
            SingleStatViewModel(id: getIdentifier(for: $0.stat),
                                title: getUILabel(for: $0.stat),
                                value: String(format: "%.1f", $0.value),
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
        case .average: return "Avg \(unit)"
        case .high: return "Peak \(unit)"
        case .latest: return "Now \(unit)"
        }
    }
    
    private func getPresentationStyle(for stat: MeasurementStatistics.Statistic) -> SingleStatViewModel.PresentationStyle {
        switch stat {
        case .average, .high: return .standard
        case .latest: return .distinct
        }
    }
}
