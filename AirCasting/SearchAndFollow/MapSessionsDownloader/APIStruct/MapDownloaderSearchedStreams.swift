// Created by Lunar on 14/03/2022.
//

import Foundation

struct MapDownloaderSearchedStreams: Codable {
    let averageValue: Double?
    let id: Int
    let maxLatitude: Double
    let maxLongitude: Double
    let measurementShortType: String
    let measurementType: String
    let measurementsCount: Int
    let minLatitude: Double
    let minLongitude: Double
    let sensorName: String
    let sensorPackageName: String
    let sessionId: Int
    let size: Int
    let startLatitude: Double?
    let startLongitude: Double?
    let thresholdHigh: Int
    let thresholdLow: Int
    let thresholdMedium: Int
    let thresholdVeryHigh: Int
    let thresholdVeryLow: Int
    let unitName: String
    let unitSymbol: String
}
