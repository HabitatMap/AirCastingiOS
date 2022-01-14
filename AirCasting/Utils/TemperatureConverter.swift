// Created by Lunar on 14/01/2022.
//

import Foundation

struct TemperatureConverter {
    static func calculateCelsius(fahrenheit: Double) -> Double {
        var celsius: Double
        
        celsius = (fahrenheit - 32) * 5 / 9
        
        return celsius
    }
}
