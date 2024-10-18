// Created by Lunar on 07/05/2021.
//

import Foundation

enum MeasurementStreamSensorName: String {
    case ab3_f = "AirBeam3-F"
    case ab3_rh = "AirBeam3-RH"
    case ab3_pm1 = "AirBeam3-PM1"
    case ab3_pm2_5 = "AirBeam3-PM2.5"
    case ab3_pm10 = "AirBeam3-PM10"
    case mini_pm1 = "AirBeamMini-PM1"
    case mini_pm2_5 = "AirBeamMini-PM2.5"
}

struct MeasurementStream: Hashable {
    let id: MeasurementStreamID?
    let sensorName: SensorName?
    let sensorPackageName: String?
    let measurementType: String?
    let measurementShortType: String?
    let unitName: String?
    let unitSymbol: String?
    let thresholdVeryHigh: Int32
    let thresholdHigh: Int32
    let thresholdMedium: Int32
    let thresholdLow: Int32
    let thresholdVeryLow: Int32
    
    let PARTICULATE_MATTER_MEASUREMENT_TYPE = "Particulate Matter"
    let PARTICULATE_MATTER_MEASUREMENT_SHORT_TYPE = "PM"
    let PARTICULATE_MATTER_UNIT_NAME = "micrograms per cubic meter"
    let PARTICULATE_MATTER_UNIT_SYMBOL = "µg/m³"
    
    let TEMPERATURE_MEASUREMENT_TYPE = "Temperature"
    let TEMPERATURE_MEASUREMENT_SHORT_TYPE = "F"
    let TEMPERATURE_UNIT_NAME = "degrees Fahrenheit"
    let TEMPERATURE_UNIT_SYMBOL = "F"
    
    let HUMIDITY_MEASUREMENT_TYPE = "Humidity"
    let HUMIDITY_MEASUREMENT_SHORT_TYPE = "RH"
    let HUMIDITY_UNIT_NAME = "PERCENT"
    let HUMIDITY_UNIT_SYMBOL = "%"
}

extension MeasurementStream {
    init(sensorName: MeasurementStreamSensorName, sensorPackageName: String) {
        switch sensorName {
        case .ab3_f:
            id = nil
            self.sensorName = sensorName.rawValue
            self.sensorPackageName = sensorPackageName
            measurementType = TEMPERATURE_MEASUREMENT_TYPE
            measurementShortType = TEMPERATURE_MEASUREMENT_SHORT_TYPE
            unitName = TEMPERATURE_UNIT_NAME
            unitSymbol = TEMPERATURE_UNIT_SYMBOL
            thresholdVeryHigh = 135
            thresholdHigh = 100
            thresholdMedium = 75
            thresholdLow = 45
            thresholdVeryLow = 15
        case .ab3_rh:
            id = nil
            self.sensorName = sensorName.rawValue
            self.sensorPackageName = sensorPackageName
            measurementType = HUMIDITY_MEASUREMENT_TYPE
            measurementShortType = HUMIDITY_MEASUREMENT_SHORT_TYPE
            unitName = HUMIDITY_UNIT_NAME
            unitSymbol = HUMIDITY_UNIT_SYMBOL
            thresholdVeryHigh = 100
            thresholdHigh = 75
            thresholdMedium = 50
            thresholdLow = 25
            thresholdVeryLow = 0
        case .ab3_pm1:
            id = nil
            self.sensorName = sensorName.rawValue
            self.sensorPackageName = sensorPackageName
            measurementType = PARTICULATE_MATTER_MEASUREMENT_TYPE
            measurementShortType = PARTICULATE_MATTER_MEASUREMENT_SHORT_TYPE
            unitName = PARTICULATE_MATTER_UNIT_NAME
            unitSymbol = PARTICULATE_MATTER_UNIT_SYMBOL
            thresholdVeryHigh = 150
            thresholdHigh = 55
            thresholdMedium = 35
            thresholdLow = 9
            thresholdVeryLow = 0
        case .ab3_pm2_5:
            id = nil
            self.sensorName = sensorName.rawValue
            self.sensorPackageName = sensorPackageName
            measurementType = PARTICULATE_MATTER_MEASUREMENT_TYPE
            measurementShortType = PARTICULATE_MATTER_MEASUREMENT_SHORT_TYPE
            unitName = PARTICULATE_MATTER_UNIT_NAME
            unitSymbol = PARTICULATE_MATTER_UNIT_SYMBOL
            thresholdVeryHigh = 150
            thresholdHigh = 55
            thresholdMedium = 35
            thresholdLow = 9
            thresholdVeryLow = 0
        case .ab3_pm10:
            id = nil
            self.sensorName = sensorName.rawValue
            self.sensorPackageName = sensorPackageName
            measurementType = PARTICULATE_MATTER_MEASUREMENT_TYPE
            measurementShortType = PARTICULATE_MATTER_MEASUREMENT_SHORT_TYPE
            unitName = PARTICULATE_MATTER_UNIT_NAME
            unitSymbol = PARTICULATE_MATTER_UNIT_SYMBOL
            thresholdVeryHigh = 200
            thresholdHigh = 100
            thresholdMedium = 50
            thresholdLow = 20
            thresholdVeryLow = 0
        case .mini_pm1:
            id = nil
            self.sensorName = sensorName.rawValue
            self.sensorPackageName = sensorPackageName
            measurementType = PARTICULATE_MATTER_MEASUREMENT_TYPE
            measurementShortType = PARTICULATE_MATTER_MEASUREMENT_SHORT_TYPE
            unitName = PARTICULATE_MATTER_UNIT_NAME
            unitSymbol = PARTICULATE_MATTER_UNIT_SYMBOL
            thresholdVeryHigh = 150
            thresholdHigh = 55
            thresholdMedium = 35
            thresholdLow = 9
            thresholdVeryLow = 0
        case .mini_pm2_5:
            id = nil
            self.sensorName = sensorName.rawValue
            self.sensorPackageName = sensorPackageName
            measurementType = PARTICULATE_MATTER_MEASUREMENT_TYPE
            measurementShortType = PARTICULATE_MATTER_MEASUREMENT_SHORT_TYPE
            unitName = PARTICULATE_MATTER_UNIT_NAME
            unitSymbol = PARTICULATE_MATTER_UNIT_SYMBOL
            thresholdVeryHigh = 150
            thresholdHigh = 55
            thresholdMedium = 35
            thresholdLow = 9
            thresholdVeryLow = 0
        }
    }
}
