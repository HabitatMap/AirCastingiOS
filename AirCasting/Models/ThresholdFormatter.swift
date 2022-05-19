// Created by Lunar on 18/05/2022.
//

import Foundation
import Resolver
import SwiftUI
import Charts

final class ThresholdFormatter: ObservableObject {
    @InjectedObject private var userSettings: UserSettings

    func floatFromThreshold(for threshold: SensorThreshold) -> [Float] {
        isCelsiusConversionOn(for: threshold) ? threshold.rawThresholdsBindingCelsius.wrappedValue : threshold.rawThresholdsBinding.wrappedValue
    }
    
    func bindingFromThreshold(for threshold: SensorThreshold) -> Binding<ThresholdsValue>  {
        isCelsiusConversionOn(for: threshold) ? threshold.thresholdsCelsiusBinding : threshold.thresholdsBinding
    }

    func celsiusUnitSymbol(for threshold: SensorThreshold) -> String {
        isCelsiusConversionOn(for: threshold) ? "C" : ""
    }
    
    func color(for threshold: SensorThreshold, from value: Double) -> Color {
        isCelsiusConversionOn(for: threshold) ? threshold.colorForCelsius(value: Int32(value)) : threshold.colorFor(value: Int32(value))
    }
    
    func convertToFahrenheit(from threshold: SensorThreshold, for averagedValue: Double?) -> Int32? {
        guard let averagedValue = averagedValue else { return nil }
        return isCelsiusConversionOn(for: threshold) ? Int32(TemperatureConverter.calculateFahrenheit(celsius: averagedValue)) : Int32(averagedValue)
    }
    
    func convertToFahrenheit(from threshold: SensorThreshold, for point: PathPoint) -> Int32 {
        isCelsiusConversionOn(for: threshold) ? Int32(TemperatureConverter.calculateFahrenheit(celsius: point.measurement)) : Int32(point.measurement)
    }
    
    func convertToFahrenheit(from threshold: SensorThreshold, for entry: ChartDataEntry) -> Int32 {
        isCelsiusConversionOn(for: threshold) ? Int32(TemperatureConverter.calculateFahrenheit(celsius: entry.y)) : Int32(entry.y)
    }
    
    func convertToFahrenheit(from threshold: SensorThreshold, for value: String) -> Int32 {
        isCelsiusConversionOn(for: threshold) ? Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(convertToInt(value)))) : convertToInt(value)
    }
    
    private func isSensorTemperature(for threshold: SensorThreshold) -> Bool { threshold.sensorName?.last == MeasurementStreamSensorName.f.rawValue.last }
    
    private func isCelsiusConversionOn(for threshold: SensorThreshold) -> Bool { isSensorTemperature(for: threshold) && userSettings.convertToCelsius }

    private func convertToInt(_ value: String) -> Int32 { Int32(value) ?? 0 }
}


