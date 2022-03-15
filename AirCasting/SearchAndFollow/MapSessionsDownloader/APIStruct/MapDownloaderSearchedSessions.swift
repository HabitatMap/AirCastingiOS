// Created by Lunar on 17/02/2022.
//

import Foundation

struct MapDownloaderSearchedSession: Codable {
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
    let streams: [String: MapDownloaderSearchedStreams]
}

