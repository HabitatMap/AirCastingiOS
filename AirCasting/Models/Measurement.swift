//
//  NewMeasurement.swift
//  AirCasting
//
//  Created by Lunar on 25/02/2021.
//

import Foundation

struct Measurement {
    var measuredValue: Double
    var packageName: String
    var sensorName: String
    var measurementType: String
    var measurementShortType: String
    var unitName: String
    var unitSymbol: String
    var thresholdVeryLow: Int
    var thresholdLow: Int
    var thresholdMedium: Int
    var thresholdHigh: Int
    var thresholdVeryHigh: Int
}
