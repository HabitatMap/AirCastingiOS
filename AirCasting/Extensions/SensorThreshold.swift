// Created by Lunar on 30/04/2021.
//

import Foundation
import SwiftUI
import Resolver

extension SensorThreshold {
    
    public var thresholdValues: ThresholdsValue {
        get {
            ThresholdsValue(veryLow: thresholdVeryLow,
                            low: thresholdLow,
                            medium: thresholdMedium,
                            high: thresholdHigh,
                            veryHigh: thresholdVeryHigh)
        }
        set {
            thresholdVeryLow = newValue.veryLow
            thresholdLow = newValue.low
            thresholdMedium = newValue.medium
            thresholdHigh = newValue.high
            thresholdVeryHigh = newValue.veryHigh
        }
    }
    
    var thresholdsBinding: Binding<ThresholdsValue> {
        Binding<ThresholdsValue> {
            self.thresholdValues
        } set: { newValue in
            self.thresholdValues = newValue
        }
    }
    
    var thresholdsCelsiusBinding: Binding<ThresholdsValue> {
        Binding<ThresholdsValue> {
            self.thresholdCelsiusValues
        } set: { newValue in
            self.thresholdCelsiusValues = newValue
        }
    }
    
    public var thresholdCelsiusValues: ThresholdsValue {
        get {
            ThresholdsValue(
                veryLow: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdVeryLow))),
                low: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdLow))),
                medium: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdMedium))),
                high: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdHigh))),
                veryHigh: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdVeryHigh)))
            )
        }
        set {
            thresholdVeryLow = Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newValue.veryLow)))
            thresholdLow = Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newValue.low)))
            thresholdMedium = Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newValue.medium)))
            thresholdHigh = Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newValue.high)))
            thresholdVeryHigh = Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newValue.veryHigh)))
        }
    }
    
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
    
    var rawThresholdsBindingCelsius: Binding<[Float]> {
        Binding<[Float]> { [self] in
            [
                Float(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdVeryLow))),
                Float(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdLow))),
                Float(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdMedium))),
                Float(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdHigh))),
                Float(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdVeryHigh)))
            ]
        } set: { [self] newThresholds in
            guard newThresholds.count >= 5 else { return }
            thresholdVeryLow = Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newThresholds[0])))
            thresholdLow = Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newThresholds[1])))
            thresholdMedium =  Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newThresholds[2])))
            thresholdHigh =  Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newThresholds[3])))
            thresholdVeryHigh =  Int32(TemperatureConverter.calculateFahrenheit(celsius: Double(newThresholds[4])))
            Log.info("\(self)")
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
        case thresholdHigh...thresholdVeryHigh:
            return .aircastingRed
        default:
            return .aircastingGray
        }
    }
    
    func colorForCelsius(value: Int32) -> Color {
        switch value {
        case Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdVeryLow))) ..< Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdLow))):
            return .aircastingGreen
        case Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdLow))) ..< Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdMedium))):
            return .aircastingYellow
        case Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdMedium))) ..< Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdHigh))):
            return .aircastingOrange
        case Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdHigh))) ... Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholdVeryHigh))):
            return .aircastingRed
        default:
            return .aircastingGray
        }
    }
}

#if DEBUG
extension SensorThreshold {
    static var mock: SensorThreshold {
        let context = Resolver.resolve(PersistenceController.self).viewContext
        
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
