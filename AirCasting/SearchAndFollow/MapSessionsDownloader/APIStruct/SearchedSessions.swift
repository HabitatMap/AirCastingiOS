// Created by Lunar on 17/02/2022.
//

import Foundation

struct SearchedSessions: Codable {
    let sessions: [SearchedSession]
}

struct SearchedSession: Codable {
    let id: Int
    let title: String
    let startTimeLocal: String
    let endTimeLocal: String
    let lastHourAverage: Double
    let isIndoor: Bool
    let latitude: Double
    let longitude: Double
    let type: String
    let username: String
    let streams: [String: SearchedStreams]
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case startTimeLocal = "start_time_local"
        case endTimeLocal = "end_time_local"
        case lastHourAverage = "last_hour_average"
        case isIndoor = "is_indoor"
        case latitude = "latitude"
        case longitude = "longitude"
        case type = "type"
        case username = "username"
        case streams = "streams"
       }
}

struct SearchedStreams: Codable {
    let averageValue: Double?
    let id: Int
    let maxLatitude: Double
    let maxLongitude: Double
    let measurementShortType: String
    let measurementType: String
    let measurementCount: Int
    let minLatitude: Double
    let minLongitude: Double
    let sensorName: String
    let sensorPackageName: String
    let sessionId: Int
    let size: Int
    let startLatitude: Double
    let startLongitude: Double
    let thresholdHigh: Int
    let thresholdLow: Int
    let thresholdMedium: Int
    let thresholdVeryHigh: Int
    let thresholdVeryLow: Int
    let unitName: String
    let unitSymbol: String
    
    enum CodingKeys: String, CodingKey {
        case averageValue = "average_value"
        case id = "id"
        case maxLatitude = "max_latitude"
        case maxLongitude = "max_longitude"
        case measurementShortType = "measurement_short_type"
        case measurementType = "measurement_type"
        case measurementCount = "measurements_count"
        case minLatitude = "min_latitude"
        case minLongitude = "min_longitude"
        case sensorName = "sensor_name"
        case sensorPackageName = "sensor_package_name"
        case sessionId = "session_id"
        case size = "size"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case thresholdHigh = "threshold_high"
        case thresholdLow = "threshold_low"
        case thresholdMedium = "threshold_medium"
        case thresholdVeryHigh = "threshold_very_high"
        case thresholdVeryLow = "threshold_very_low"
        case unitName = "unit_name"
        case unitSymbol = "unit_symbol"
       }
}

