// Created by Lunar on 31/03/2022.
//

import SwiftUI

extension ThresholdsValue {
    func colorFor(value: Double) -> Color {
        switch Int32(value) {
        case veryLow...low:
            return .aircastingGreen
        case low + 1...medium:
            return .aircastingYellow
        case medium + 1...high:
            return .aircastingOrange
        case high + 1...veryHigh:
            return .aircastingRed
        default:
            return .aircastingGray
        }
    }
}
