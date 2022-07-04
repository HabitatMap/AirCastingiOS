// Created by Lunar on 04/05/2022.
//

import Foundation

struct ExternalSessionWithStreamsAndMeasurements {
    let uuid: SessionUUID
    let provider: String
    let name: String
    let startTime: Date
    let endTime: Date
    let longitude: Double
    let latitude: Double
    var streams: [Stream]
    
    struct Stream {
        let id: Int
        let unitName: String
        let unitSymbol: String
        let measurementShortType: String
        let measurementType: String
        let sensorName: String
        let sensorPackageName: String
        let thresholdsValues: ThresholdsValue
        var measurements: [Measurement]
    }
    
    struct Measurement {
        let value: Double
        let time: Date
        let latitude: Double
        let longitude: Double
    }
}
