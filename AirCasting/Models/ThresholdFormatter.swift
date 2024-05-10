// Created by Lunar on 18/05/2022.
//

import Foundation
import Resolver
import SwiftUI

protocol ThresholdFormatter {
    func value(from string: String) -> Int32?
    func value(from double: Double) -> Int32
    func formattedNumerics() -> [Float]
    func color(for value: Double) -> Color
    func formattedBinding() -> Binding<ThresholdsValue>
}

final class TemperatureThresholdFormatter: ThresholdFormatter {
    @InjectedObject private var userSettings: UserSettings
    private let threshold: SensorThreshold
    
    init(threshold: SensorThreshold) {
        self.threshold = threshold
    }
    
    func value(from string: String) -> Int32? {
        guard let intValue = Int32(string) else { return nil }
        guard isSensorTemperature(for: threshold) else { return intValue }
        switch temperatureUnit {
        case .fahrenheit:
            return intValue
        case .celsius:
            return Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(intValue)))
        }
    }

    func value(from double: Double) -> Int32 {
        let intValue = Int32(double)
        guard isSensorTemperature(for: threshold) else { return intValue }
        switch temperatureUnit {
        case .fahrenheit:
            return intValue
        case .celsius:
            return Int32(TemperatureConverter.calculateFahrenheit(celsius: double))
        }
    }
    
    func formattedNumerics() -> [Float] {
        guard isSensorTemperature(for: threshold) else { return threshold.rawThresholdsBinding.wrappedValue }
        switch temperatureUnit {
        case .fahrenheit:
            return threshold.rawThresholdsBinding.wrappedValue
        case .celsius:
            return threshold.rawThresholdsBindingCelsius.wrappedValue
        }
    }
    
    func color(for value: Double) -> Color {
        guard isSensorTemperature(for: threshold) else { return threshold.colorFor(value: Int32(value)) }
        switch temperatureUnit {
        case .fahrenheit:
            return threshold.colorFor(value: Int32(value))
        case .celsius:
           return threshold.colorForCelsius(value: Int32(value))
        }
    }
    
    func formattedBinding() -> Binding<ThresholdsValue> {
        guard isSensorTemperature(for: threshold) else { return threshold.thresholdsBinding }
        
        switch temperatureUnit {
        case .fahrenheit:
            return threshold.thresholdsBinding
        case .celsius:
            return threshold.thresholdsCelsiusBinding
        }
    }
    
    private enum TemperatureUnit {
        case fahrenheit
        case celsius
    }
    
    private var temperatureUnit: TemperatureUnit {
        userSettings.convertToCelsius ? .celsius : .fahrenheit
    }
    
    private func isSensorTemperature(for threshold: SensorThreshold) -> Bool {
        threshold.sensorName?.last == MeasurementStreamSensorName.ab3_f.rawValue.last
    }
}
