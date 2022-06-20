// Created by Lunar on 26/04/2022.
//

import Foundation

struct MeasurementsDownloaderResultModel: Decodable {
    let id: Int
    let streams: [Stream]
    
    struct Stream: Decodable {
        let streamId: Int
        let sensorName: String
        let thresholdVeryLow: Int32
        let thresholdLow: Int32
        let thresholdMedium: Int32
        let thresholdHigh: Int32
        let thresholdVeryHigh: Int32
        let unitName: String
        let measurementShortType: String
        let measurementType: String
        let sensorUnit: String
        let measurements: [Measurement]
    }
    
    struct Measurement: Decodable {
        let value: Double
        let time: Double
        let longitude: Double
        let latitude: Double
    }
}

