// Created by Lunar on 28/04/2021.
//

import SwiftUI
import Resolver

struct MeasurementDotView: View {
    
    let value: Double
    @ObservedObject var thresholds: SensorThreshold
    @InjectedObject private var userSettings: UserSettings

    var body: some View {
        color
            .clipShape(Circle())
            .frame(width: 5, height: 5)
    }
    
    var color: Color {
        if thresholds.sensorName == MeasurementStreamSensorName.f.rawValue && userSettings.convertToCelsius {
            switch Int32(value) {
            case Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds.thresholdVeryLow))) ..< Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds.thresholdLow))):
                return Color.aircastingGreen
            case Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds.thresholdLow))) ..< Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds.thresholdMedium))):
                return Color.aircastingYellow
            case Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds.thresholdMedium))) ..< Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds.thresholdHigh))):
                return Color.aircastingOrange
            case Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds.thresholdHigh))) ... Int32(TemperatureConverter.calculateCelsius(fahrenheit: Double(thresholds.thresholdVeryHigh))):
                return Color.aircastingRed
            default:
                return Color.aircastingGray
            }
        } else {
            switch Int32(value) {
            case thresholds.thresholdVeryLow ..< thresholds.thresholdLow:
                return Color.aircastingGreen
            case thresholds.thresholdLow ..< thresholds.thresholdMedium:
                return Color.aircastingYellow
            case thresholds.thresholdMedium ..< thresholds.thresholdHigh :
                return Color.aircastingOrange
            case thresholds.thresholdHigh ... thresholds.thresholdVeryHigh :
                return Color.aircastingRed
            default:
                return Color.aircastingGray
            }
        }
    }
}

#if DEBUG
struct MeasurementDotView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementDotView(value: 15.0, thresholds: .mock)
    }
}
#endif
