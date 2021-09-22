// Created by Lunar on 30/04/2021.
//

import Foundation
import SwiftUI

extension SensorThreshold {
    
    var rawThresholdsBinding: Binding<[Float]> {
        Binding<[Float]> { [self] in
            [
                Float(thresholdVeryLow),
                Float(thresholdLow),
                Float(thresholdMedium),
                Float(thresholdHigh),
                Float(thresholdVeryHigh)
            ]
        } set: { [self] newThresholds in
            guard newThresholds.count >= 5 else { return }
            thresholdVeryLow = Int32(newThresholds[0])
            thresholdLow = Int32(newThresholds[1])
            thresholdMedium = Int32(newThresholds[2])
            thresholdHigh = Int32(newThresholds[3])
            thresholdVeryHigh = Int32(newThresholds[4])
        }
    }
}

extension SensorThreshold {
    func colorFor(value: Int32) -> Color {
        switch value {
        case thresholdVeryLow..<thresholdLow:
            return .aircastingGreen
        case thresholdLow..<thresholdMedium:
            return .aircastingYellow
        case thresholdMedium..<thresholdHigh:
            return .aircastingOrange
        case thresholdHigh..<thresholdVeryHigh:
            return .aircastingRed
        default:
            return .aircastingGray
        }
    }
}

#if DEBUG
extension SensorThreshold {
    static var mock: SensorThreshold {
        let context = PersistenceController.shared.viewContext
        
        if let existing = try! context.existingObject(sensorName: "mock-threshold") {
            return existing
        }
        
        let threshold: SensorThreshold = try! context.newOrExisting(sensorName: "mock-threshold")

        threshold.thresholdVeryLow = -100
        threshold.thresholdLow = -40
        threshold.thresholdMedium = -30
        threshold.thresholdHigh = -20
        threshold.thresholdVeryHigh = 10

        return threshold
    }
}
#endif
