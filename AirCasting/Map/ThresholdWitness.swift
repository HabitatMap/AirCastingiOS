// Created by Lunar on 26/10/2021.
//
import Foundation

struct ThresholdWitness: Equatable {
    
    let thresholdHigh: Int32
    let thresholdLow: Int32
    let thresholdMedium: Int32
    let thresholdVeryHigh: Int32
    let thresholdVeryLow: Int32
    
    init?(sensorThreshold: SensorThreshold?) {
        guard let sensorThreshold = sensorThreshold else { return nil }
        self.thresholdHigh = sensorThreshold.thresholdHigh
        self.thresholdLow = sensorThreshold.thresholdLow
        self.thresholdMedium = sensorThreshold.thresholdMedium
        self.thresholdVeryHigh = sensorThreshold.thresholdVeryHigh
        self.thresholdVeryLow = sensorThreshold.thresholdVeryLow
    }
}
