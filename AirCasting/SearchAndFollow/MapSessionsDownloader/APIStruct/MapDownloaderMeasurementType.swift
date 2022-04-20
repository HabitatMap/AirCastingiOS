// Created by Lunar on 17/02/2022.
//

import Foundation

enum MapDownloaderMeasurementType: Codable {
    case particulateMatter
    case ozone
}

extension MapDownloaderMeasurementType {
    var apiName: String {
        switch self {
        case .particulateMatter: return "Particulate Matter"
        case .ozone: return "Ozone"
        }
    }
    
    var apiNameSufix: String {
        switch self {
        case .particulateMatter: return "-pm2.5"
        case .ozone: return "-o3"
        }
    }
    
    var capitalizedName: String {
        switch self {
        case .particulateMatter: return Strings.SearchFollowParamNames.particulateMatter
        case .ozone: return Strings.SearchFollowParamNames.ozone
        }
    }
}
