// Created by Lunar on 04/04/2022.
//

import Foundation

enum MapDownloaderSensorType: Codable, CaseIterable {
    case AB3and2
    case OpenAQ
    case PurpleAir
    case OzoneSensor
}

extension MapDownloaderSensorType {
    var apiName: String {
        switch self {
        case .AB3and2: return "airbeam-pm2.5"
        case .OpenAQ: return "openaq-pm2.5"
        case .PurpleAir: return "purpleair-pm2.5"
        case .OzoneSensor: return "openaq-o3"
        }
    }
    
    var capitalizedName: String {
        switch self {
        case .AB3and2: return Strings.SearchFollowSensorNames.AirBeam3and2
        case .OpenAQ: return Strings.SearchFollowSensorNames.openAQ
        case .PurpleAir: return Strings.SearchFollowSensorNames.purpleAir
        case .OzoneSensor: return Strings.SearchFollowSensorNames.openAQOzone
        }
    }
}
