// Created by Lunar on 17/02/2022.
//

import Foundation

enum MapDownloaderMeasurementType: Codable {
    case particulateMatter
    case ozone
    case nitrogenDioxide
}

extension MapDownloaderMeasurementType {
    var apiName: String {
        switch self {
        case .particulateMatter: return "Particulate Matter"
        case .ozone: return "Ozone"
        case .nitrogenDioxide: return "Nitrogen Dioxide"
        }
    }
    
    var sensorNameSuffix: String {
        switch self {
        case .particulateMatter: return "-pm2.5"
        case .ozone: return "-o3"
        case .nitrogenDioxide: return "-no2"
        }
    }
    
    var capitalizedName: String {
        switch self {
        case .particulateMatter: return Strings.SearchFollowParamNames.particulateMatter
        case .ozone: return Strings.SearchFollowParamNames.ozone
        case .nitrogenDioxide: return Strings.SearchFollowParamNames.nitrogenDioxide
        }
    }
}
