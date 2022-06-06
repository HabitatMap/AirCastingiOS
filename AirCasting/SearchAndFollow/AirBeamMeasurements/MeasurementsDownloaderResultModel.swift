// Created by Lunar on 26/04/2022.
//

import Foundation

struct MeasurementsDownloaderResultModel: Decodable {
    let streamId: Int
    let sensorUnit: String
    let sensorName: String
    let measurements: [Measurement]
    
    struct Measurement: Decodable {
        let value: Double
        let time: Double
        let longitude: Double
        let latitude: Double
    }
}

