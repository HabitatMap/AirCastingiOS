// Created by Lunar on 18/05/2022.
//

import Foundation
import Resolver
import SwiftUI
import Charts

final class ThresholdFormatter: ObservableObject {
    enum TemperatureUnit {
        case fahrenheit
        case celsius
    }
    
    @InjectedObject private var userSettings: UserSettings
    private var currentTemperatureUnit: TemperatureUnit = .fahrenheit
    let threshold: SensorThreshold
    
    init(for threshold: SensorThreshold) {
        self.threshold = threshold
        currentTemperatureUnit = conversionIsOnFor()
    }

    func formattedFloat() -> [Float] {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return threshold.rawThresholdsBinding.wrappedValue
        case .celsius:
            return threshold.rawThresholdsBindingCelsius.wrappedValue
        }
    }
    
    func formattedBinding() -> Binding<ThresholdsValue>  {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return threshold.thresholdsBinding
        case .celsius:
            return threshold.thresholdsCelsiusBinding
        }
    }

    func formattedUnitSymbol() -> String {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return Strings.SingleMeasurementView.fahrenheitUnit
        case .celsius:
            return Strings.SingleMeasurementView.celsiusUnit
        }
    }
    
    func formattedColor(for value: Double) -> Color {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return threshold.colorFor(value: Int32(value))
        case .celsius:
           return threshold.colorForCelsius(value: Int32(value))
        }
    }
    
    func formattedToFahrenheit(for averagedValue: Double) -> Int32 {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return Int32(averagedValue)
        case .celsius:
            return Int32(TemperatureConverter.calculateFahrenheit(celsius: averagedValue))
        }
    }
    
    func formattedToFahrenheit(for point: PathPoint) -> Int32 {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return Int32(point.measurement)
        case .celsius:
            return Int32(TemperatureConverter.calculateFahrenheit(celsius: point.measurement))
        }
    }
    
    func formattedToFahrenheit(for entry: ChartDataEntry) -> Int32 {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return Int32(entry.y)
        case .celsius:
            return Int32(TemperatureConverter.calculateFahrenheit(celsius: entry.y))
        }
    }
    
    func formattedToFahrenheit(for value: String) -> Int32 {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return convertToInt(value)
        case .celsius:
            return Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(convertToInt(value))))
        }
    }
    
    func formattedToCelsius(for thresholds: [Float], at index: Int) -> Int {
        switch currentTemperatureUnit {
        case .fahrenheit:
            return Int(thresholds[index])
        case .celsius:
            return Int(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds[index])))
        }
    }
    
    private func isSensorTemperature() -> Bool { threshold.sensorName?.last == MeasurementStreamSensorName.f.rawValue.last }
    
    private func conversionIsOnFor() -> TemperatureUnit {
        if isSensorTemperature() && userSettings.convertToCelsius {
            return .celsius
        } else {
            return .fahrenheit
        }
    }

    private func convertToInt(_ value: String) -> Int32 { Int32(value) ?? 0 }
}
