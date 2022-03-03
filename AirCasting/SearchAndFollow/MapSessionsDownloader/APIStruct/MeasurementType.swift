// Created by Lunar on 17/02/2022.
//

import Foundation

enum MeasurementType: Codable {
    case particulateMatter
    case ozone
}

extension MeasurementType {
    var name: String {
        switch self {
        case .particulateMatter: return "Particulate Matter"
        case .ozone: return ""
        }
    }
}
