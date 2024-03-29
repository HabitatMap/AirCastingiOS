// Created by Lunar on 14/12/2021.
//

import Foundation

public struct ThresholdsValue {
    
    let veryLow: Int32
    let low: Int32
    let medium: Int32
    let high: Int32
    let veryHigh: Int32
    
    var toArray: [Int32] {
        [veryLow, low, medium, high, veryHigh]
    }
    
    public init(veryLow: Int32, low: Int32, medium: Int32, high: Int32, veryHigh: Int32) {
        self.veryLow = veryLow
        self.low = low
        self.medium = medium
        self.high = high
        self.veryHigh = veryHigh
    }
    
    func convertedToCelsius() -> Self {
        .init(veryLow: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(veryLow))),
              low: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(low))),
              medium: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(medium))),
              high: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(high))),
              veryHigh: Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(veryHigh))))
    }
}
