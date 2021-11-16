// Created by Lunar on 15/11/2021.
//

import Foundation

class ThresholdSettingsViewModel: ObservableObject {
    
    @Published var thresholdVeryLow = ""
    @Published var thresholdLow = ""
    @Published var thresholdMedium = ""
    @Published var thresholdHigh = ""
    @Published var thresholdVeryHigh = ""
    let initialThresholds: [Int32]
    
    init(initialThresholds: [Int32]) {
        self.initialThresholds = initialThresholds
    }
    
    private func convertToFloat(value: String) -> Float {
        let floatValue = Float(value) ?? 0
        return floatValue
    }
    
    func resetToDefault() -> [Float] {
        var newInitial: [Float] = []
        for value in initialThresholds {
            let newValue = Float(value)
            newInitial.append(newValue)
        }
        return newInitial
    }
    
    func updateToNewThresholds() -> [Float] {
        let stringThresholdValues = [thresholdVeryHigh, thresholdHigh, thresholdMedium, thresholdLow, thresholdVeryLow]
        var newThresholdValues: [Float] = []
        for value in stringThresholdValues {
            let convertedValue = convertToFloat(value: value)
            newThresholdValues.append(convertedValue)
        }
        return newThresholdValues.sorted { $0 < $1 }
    }
}
