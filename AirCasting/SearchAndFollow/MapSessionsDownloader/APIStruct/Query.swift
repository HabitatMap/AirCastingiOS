// Created by Lunar on 17/02/2022.
//

import Foundation

struct Query: Codable {
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
    let sensor_name: String
    let measurement_type: String
    let unitSymbol: String
    
    enum CodingKeys: String, CodingKey {
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case tags = "tags"
        case usernames = "usernames"
        case west = "west"
        case east = "east"
        case south = "south"
        case north = "north"
        case limit = "limit"
        case offset = "offset"
        case sensor_name = "sensor_name"
        case measurement_type = "measurement_type"
        case unitSymbol = "unit_symbol"
       }
}
