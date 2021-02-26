//
//  NewMeasurement.swift
//  AirCasting
//
//  Created by Lunar on 25/02/2021.
//

import Foundation

struct NewMeasurement {
    
    let packageName: String
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
    let measuredValue: Double
    
}
