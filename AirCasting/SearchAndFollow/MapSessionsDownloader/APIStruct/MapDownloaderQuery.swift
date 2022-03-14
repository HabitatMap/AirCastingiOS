// Created by Lunar on 17/02/2022.
//

import Foundation

struct MapDownloaderQuery: Codable {
    let timeFrom: String
    let timeTo: String
    let tags: String
    let usernames: String
    let west: Double
    let east: Double
    let south: Double
    let north: Double
    let limit: Double
    let offset: Double
    let sensorName: String
    let measurementType: String
    let unitSymbol: String
}
