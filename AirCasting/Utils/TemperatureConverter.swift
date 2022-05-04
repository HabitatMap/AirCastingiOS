// Created by Lunar on 14/01/2022.
//

import Foundation

struct TemperatureConverter {
    static func calculateCelsius(fahrenheit: Double) -> Double {
        ((fahrenheit - 32) * 5 / 9).rounded()
    }
    
    static func calculateFahrenheit(celsius: Double) -> Double {
        32 + 9 / 5 * celsius
    }
}
