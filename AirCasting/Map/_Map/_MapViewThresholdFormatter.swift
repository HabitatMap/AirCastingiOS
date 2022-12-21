// Created by Lunar on 18/11/2022.
//

import SwiftUI
import Resolver

class _MapViewThresholdFormatter {
    
    static let shared = _MapViewThresholdFormatter()
    
    func color(points: [_MapView.PathPoint], threshold: SensorThreshold) -> UIColor {
        let formatter = Resolver.resolve(ThresholdFormatter.self, args: threshold)
        guard let point = points.last else { return .white }
        let measurement = formatter.value(from: point.value)
        return getProperColor(value: measurement, threshold: threshold)
    }
    
    func getProperColor(value: Int32, threshold: SensorThreshold?) -> UIColor {
        guard let threshold = threshold else { return .white }
        
        let veryLow = threshold.thresholdVeryLow
        let low = threshold.thresholdLow
        let medium = threshold.thresholdMedium
        let high = threshold.thresholdHigh
        let veryHigh = threshold.thresholdVeryHigh
        
        switch value {
        case veryLow ..< low:
            return UIColor.aircastingGreen
        case low ..< medium:
            return UIColor.aircastingYellow
        case medium ..< high:
            return UIColor.aircastingOrange
        case high ... veryHigh:
            return UIColor.aircastingRed
        default:
            return UIColor.aircastingGray
        }
    }
}
