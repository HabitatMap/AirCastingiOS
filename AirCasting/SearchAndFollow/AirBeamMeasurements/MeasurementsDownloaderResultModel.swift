// Created by Lunar on 26/04/2022.
//

import Foundation

struct MeasurementsDownloaderResultModel: Decodable {
    let sensorName: String
    let measurements: [theMeasurement]
}

struct theMeasurement: Decodable {
    let value: Double
    let time: Double
    let longitude: Double
    let latitude: Double
}
