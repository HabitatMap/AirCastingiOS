// Created by Lunar on 31/03/2022.
//

import SwiftUI

extension ThresholdsValue {
    func colorFor(value: Double) -> Color {
        switch Int32(value) {
        case veryLow..<low:
            return .aircastingGreen
        case low..<medium:
            return .aircastingYellow
        case medium..<high:
            return .aircastingOrange
        case high...veryHigh:
            return .aircastingRed
        default:
            return .aircastingGray
        }
    }
}
