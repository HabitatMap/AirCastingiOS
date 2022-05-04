// Created by Lunar on 04/05/2022.
//

import Foundation

struct ExternalSessionWithStreamsAndMeasurements {
    let uuid: String
    let provider: String
    let name: String
    let startTime: Date
    let endTime: Date
    let longitude: Double
    let latitude: Double
    let streams: [Stream]
    
    struct Stream {
        let id: Int
        let unitName: String
        let unitSymbol: String
        let measurementShortType: String
        let measurementType: String
        let sensorName: String
        let sensorPackageName: String
        let thresholdVeryLow: Int32
        let thresholdLow: Int32
        let thresholdMedium: Int32
        let thresholdHigh: Int32
        let thresholdVeryHigh: Int32
        let measurements: [Measurement]
    }
    
    struct Measurement {
        let value: Double
        let time: Date
        let latitude: Double
        let longitude: Double
    }
}
