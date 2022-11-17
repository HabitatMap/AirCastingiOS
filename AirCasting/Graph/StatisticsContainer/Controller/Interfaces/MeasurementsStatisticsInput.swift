// Created by Lunar on 06/07/2021.
//

import Foundation

protocol MeasurementsStatisticsInput {
    func computeStatistics()
    /// When continous mode is enabled it will allow for a time-based stats refreshing
    var continuousModeEnabled: Bool { get set }
}
