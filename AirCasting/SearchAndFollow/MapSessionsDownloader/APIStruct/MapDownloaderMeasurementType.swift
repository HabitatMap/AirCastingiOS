// Created by Lunar on 17/02/2022.
//

import Foundation

enum MapDownloaderMeasurementType: Codable, CaseIterable {
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
    
    var capitalizedName: String {
        switch self {
        case .particulateMatter: return Strings.SearchFollowParamNames.particulateMatter
        case .ozone: return Strings.SearchFollowParamNames.ozone
        }
    }
}
