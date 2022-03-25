// Created by Lunar on 17/02/2022.
//

import Foundation

enum MapDownloaderMeasurementType: Codable {
    case particulateMatter
    case ozone
}

extension MapDownloaderMeasurementType {
    var name: String {
        switch self {
        case .particulateMatter: return "Particulate Matter"
        case .ozone: return "Ozone"
        }
    }
}
