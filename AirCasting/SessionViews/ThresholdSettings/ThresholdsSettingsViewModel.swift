// Created by Lunar on 15/11/2021.
//

import Foundation

class ThresholdSettingsViewModel: ObservableObject {
    
    @Published var thresholdVeryLow = ""
    @Published var thresholdLow = ""
    @Published var thresholdMedium = ""
    @Published var thresholdHigh = ""
    @Published var thresholdVeryHigh = ""
    let initialThresholds: ThresholdsValue
    
    init(initialThresholds: ThresholdsValue) {
        self.initialThresholds = initialThresholds
    }
    
    func resetToDefault() -> ThresholdsValue {
        return initialThresholds
    }
    
    func updateToNewThresholds() -> ThresholdsValue {
        let stringThresholdValues = [thresholdVeryHigh, thresholdHigh, thresholdMedium, thresholdLow, thresholdVeryLow]
        var newThresholdValues: [Int32] = []
        for value in stringThresholdValues {
            let convertedValue = convertToInt(value)
            newThresholdValues.append(convertedValue)
        }
        let sortedValue = newThresholdValues.sorted { $0 < $1 }
        return ThresholdsValue(array: sortedValue)
    }
    
    private func convertToInt(_ value: String) -> Int32 {
        let intValue = Int32(value) ?? 0
        return intValue
    }
}
