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
    @InjectedObject private var userSettings: UserSettings
    
    init(initialThresholds: ThresholdsValue, threshold: SensorThreshold) {
        self.initialThresholds = initialThresholds
        self.threshold = threshold
    }

    func resetToDefault() -> ThresholdsValue {
        if threshold.sensorName == MeasurementStreamSensorName.f.rawValue && userSettings.convertToCelsius {
            return ThresholdsValue(
                veryLow: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(initialThresholds.veryLow))),
                low: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(initialThresholds.low))),
                medium: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(initialThresholds.medium))),
                high: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(initialThresholds.high))),
                veryHigh: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(initialThresholds.veryHigh)))
            )
        } else {
            return initialThresholds
        }
    }
    
    func updateToNewThresholds() -> ThresholdsValue {
        let stringThresholdValues = [thresholdVeryHigh, thresholdHigh, thresholdMedium, thresholdLow, thresholdVeryLow]
        var newThresholdValues: [Int32] = []
        for value in stringThresholdValues {
            let convertedValue = convertToInt(value)
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
