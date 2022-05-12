// Created by Lunar on 15/11/2021.
//

import Foundation
import Resolver

class ThresholdSettingsViewModel: ObservableObject {
    
    @Published var thresholdVeryLow = ""
    @Published var thresholdLow = ""
    @Published var thresholdMedium = ""
    @Published var thresholdHigh = ""
    @Published var thresholdVeryHigh = ""
    let initialThresholds: ThresholdsValue
    var threshold: SensorThreshold
    var selectedStream: MeasurementStreamEntity
    @InjectedObject private var userSettings: UserSettings
    
    init(initialThresholds: ThresholdsValue, threshold: SensorThreshold, selectedStream: MeasurementStreamEntity) {
        self.initialThresholds = initialThresholds
        self.threshold = threshold
        self.selectedStream = selectedStream
    }

    func resetToDefault() -> ThresholdsValue { initialThresholds }
    
    func updateToNewThresholds() -> ThresholdsValue {
        let stringThresholdValues = [thresholdVeryHigh, thresholdHigh, thresholdMedium, thresholdLow, thresholdVeryLow]
        var newThresholdValues: [Int32] = []
        for value in stringThresholdValues {
            let convertedValue = selectedStream.isTemperature && userSettings.convertToCelsius ? Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(convertToInt(value)))) : convertToInt(value)
            newThresholdValues.append(convertedValue)
        }
        let sortedValue = newThresholdValues.sorted { $0 < $1 }
        return ThresholdsValue(veryLow: sortedValue[0],
                               low: sortedValue[1],
                               medium: sortedValue[2],
                               high: sortedValue[3],
                               veryHigh: sortedValue[4])
    }
    
    private func convertToInt(_ value: String) -> Int32 { Int32(value) ?? 0 }
}
