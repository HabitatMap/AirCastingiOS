// Created by Lunar on 06/07/2021.
//

import Foundation

protocol MeasurementsStatisticsInput {
    func computeStatistics()
    //TODO: Comment
    var continuousModeEnabled: Bool { get set }
}
