// Created by Lunar on 04/04/2022.
//

import Foundation

enum MapDownloaderSensorType: Codable {
    case AB325
    case AB225
    case OpenAQ
    case OzoneSensor
}

extension MapDownloaderSensorType {
    var apiName: String {
        switch self {
        case .AB325: return "airbeam3-pm2.5"
        case .AB225: return "airbeam2-pm2.5"
        case .OpenAQ: return"openaq-pm2.5"
        case .OzoneSensor: return "openaq-o3"
        }
    }
    
    var capitalizedName: String {
        switch self {
        case .AB325: return Strings.SearchFollowSensorNames.AirBeam325
        case .AB225: return Strings.SearchFollowSensorNames.AirBeam225
        case .OpenAQ: return Strings.SearchFollowSensorNames.openAQ
        case .OzoneSensor: return Strings.SearchFollowSensorNames.openAQOzone
        }
    }
}
