// Created by Lunar on 06/07/2021.
//

import Foundation
import SwiftUI

final class StatisticsContainerViewModel: StatisticsContainerViewModelable, MeasurementsStatisticsOutput {
    private var statsInput: MeasurementsStatisticsInput
    
    init(statsInput: MeasurementsStatisticsInput) {
        self.statsInput = statsInput
        statsInput.computeStatistics()
    }
    
    @Published var stats: [SingleStatViewModel] = []
    
    var continuousModeEnabled: Bool {
        get { statsInput.continuousModeEnabled }
        set { statsInput.continuousModeEnabled = newValue }
    }
    
    func adjustForNewData() {
        statsInput.computeStatistics()
    }
    
    func statisticsDidChange(to newStats: [MeasurementStatistics.StatisticItem]) {
        stats = newStats.map {
            SingleStatViewModel(id: getIdentifier(for: $0.stat),
                                title: getUILabel(for: $0.stat),
                                value: $0.value,
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
}
