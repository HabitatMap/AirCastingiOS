// Created by Lunar on 04/04/2022.
//

import Foundation

enum MapDownloaderSensorType: Codable {
    case AirBeam
    case Govt
}

extension MapDownloaderSensorType {
    var sensorNamePrefix: String {
        switch self {
        case .AirBeam: return "airbeam"
        case .Govt: return "government"
        }
    }
    
    var capitalizedName: String {
        switch self {
        case .AirBeam: return Strings.SearchFollowSensorNames.AirBeam3and2
        case .Govt: return Strings.SearchFollowSensorNames.Govt
        }
    }
}
