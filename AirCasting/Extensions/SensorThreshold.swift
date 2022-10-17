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
            thresholdVeryLow = newValue.veryLow
            thresholdLow = newValue.low
            thresholdMedium = newValue.medium
            thresholdHigh = newValue.high
            thresholdVeryHigh = newValue.veryHigh
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
        }
    }
}

extension SensorThreshold {
    func colorFor(value: Int32) -> Color {
        switch value {
        case thresholdVeryLow...thresholdLow:
            return .aircastingGreen
        case thresholdLow + 1...thresholdMedium:
            return .aircastingYellow
        case thresholdMedium + 1...thresholdHigh:
            return .aircastingOrange
        case thresholdHigh + 1...thresholdVeryHigh:
            return .aircastingRed
        default:
            return .aircastingGray
        }
    }
    
    func colorForCelsius(value: Double) -> Color {
        switch value {
        case Double(thresholdCelsiusValues.veryLow) ... Double(thresholdCelsiusValues.low):
            return .aircastingGreen
        case Double(thresholdCelsiusValues.low).nextUp ..< Double(thresholdCelsiusValues.medium).nextUp:
            return .aircastingYellow
        case Double(thresholdCelsiusValues.medium).nextUp ..< Double(thresholdCelsiusValues.high).nextUp:
            return .aircastingOrange
        case Double(thresholdCelsiusValues.high).nextUp ..< Double(thresholdCelsiusValues.veryHigh).nextUp:
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
