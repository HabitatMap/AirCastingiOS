// Created by Lunar on 06/12/2021.
//

import Foundation

struct CSVMeasurementStream {
    let sensorName: String
    let measurementType: String
    let measurementShortType: String
    let unitName: String
    let unitSymbol: String
    let thresholdVeryLow: Int
    let thresholdLow: Int
    let thresholdMedium: Int
    let thresholdHigh: Int
    let thresholdVeryHigh: Int
    
    private static let DEVICE_NAME = "AirBeam3"
    private static let PM_MEASUREMENT_TYPE = "Particulate Matter"
    private static let PM_MEASUREMENT_SHORT_TYPE = "PM"
    private static let PM_UNIT_NAME = "microgram per cubic meter"
    private static let PM_UNIT_SYMBOL = "µg/m³"
    static let SUPPORTED_STREAMS: [SDCardCSVFileFactory.Header : CSVMeasurementStream] = [
        SDCardCSVFileFactory.Header.f : CSVMeasurementStream(sensorName: MeasurementStreamSensorName.ab3_f.rawValue,
                                        measurementType: "Temperature",
                                        measurementShortType: "F",
                                        unitName: "fahrenheit",
                                        unitSymbol: "F",
                                        thresholdVeryLow: 15,
                                        thresholdLow: 45,
                                        thresholdMedium: 75,
                                        thresholdHigh: 105,
                                        thresholdVeryHigh: 135),
        
        SDCardCSVFileFactory.Header.rh : CSVMeasurementStream(sensorName: MeasurementStreamSensorName.ab3_rh.rawValue,
                                         measurementType: "Humidity",
                                         measurementShortType: "RH",
                                         unitName: "percent",
                                         unitSymbol: "%",
                                         thresholdVeryLow: 0,
                                         thresholdLow: 25,
                                         thresholdMedium: 50,
                                         thresholdHigh: 75,
                                         thresholdVeryHigh: 100),
        
        SDCardCSVFileFactory.Header.pm1 : CSVMeasurementStream(sensorName: MeasurementStreamSensorName.ab3_pm1.rawValue,
                                          measurementType: PM_MEASUREMENT_TYPE,
                                          measurementShortType: PM_MEASUREMENT_SHORT_TYPE,
                                          unitName: PM_UNIT_NAME,
                                          unitSymbol: PM_UNIT_SYMBOL,
                                          thresholdVeryLow: 0,
                                          thresholdLow: 12,
                                          thresholdMedium: 35,
                                          thresholdHigh: 55,
                                          thresholdVeryHigh: 150),
        
        SDCardCSVFileFactory.Header.pm2_5 : CSVMeasurementStream(sensorName: MeasurementStreamSensorName.ab3_pm2_5.rawValue,
                                            measurementType: PM_MEASUREMENT_TYPE,
                                            measurementShortType: PM_MEASUREMENT_SHORT_TYPE,
                                            unitName: PM_UNIT_NAME,
                                            unitSymbol: PM_UNIT_SYMBOL,
                                            thresholdVeryLow: 0,
                                            thresholdLow: 12,
                                            thresholdMedium: 35,
                                            thresholdHigh: 55,
                                            thresholdVeryHigh: 150),
        
        SDCardCSVFileFactory.Header.pm10 : CSVMeasurementStream(sensorName: MeasurementStreamSensorName.ab3_pm10.rawValue,
                                           measurementType: PM_MEASUREMENT_TYPE,
                                           measurementShortType: PM_MEASUREMENT_SHORT_TYPE,
                                           unitName: PM_UNIT_NAME,
                                           unitSymbol: PM_UNIT_SYMBOL,
                                           thresholdVeryLow: 0,
                                           thresholdLow: 20,
                                           thresholdMedium: 50,
                                           thresholdHigh: 100,
                                           thresholdVeryHigh: 200)
    ]
}
