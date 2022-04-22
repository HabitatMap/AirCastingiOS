// Created by Lunar on 04/04/2022.
//

import Foundation

enum MapDownloaderSensorType: Codable {
    case AB3and2
    case OpenAQ
    case PurpleAir
}

extension MapDownloaderSensorType {
    var sensorNamePrefix: String {
        switch self {
        case .AB3and2: return "airbeam"
        case .OpenAQ: return "openaq"
        case .PurpleAir: return "purpleair"
        }
    }
    
    var capitalizedName: String {
        switch self {
        case .AB3and2: return Strings.SearchFollowSensorNames.AirBeam3and2
        case .OpenAQ: return Strings.SearchFollowSensorNames.openAQ
        case .PurpleAir: return Strings.SearchFollowSensorNames.purpleAir
        }
    }
}
