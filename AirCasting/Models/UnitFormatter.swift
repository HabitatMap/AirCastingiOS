// Created by Lunar on 30/05/2022.
//

import Foundation
import Resolver

protocol UnitFormatter {
    func unitString(for stream: MeasurementStreamEntity) -> String
}

final class TemperatureUnitFormatter: UnitFormatter {
    @InjectedObject private var userSettings: UserSettings
    
    func unitString(for stream: MeasurementStreamEntity) -> String {
        guard stream.isTemperature else { return stream.sensorName ?? "" }
        return userSettings.convertToCelsius ? Strings.SingleMeasurementView.celsiusUnit : Strings.SingleMeasurementView.fahrenheitUnit
    }
}
