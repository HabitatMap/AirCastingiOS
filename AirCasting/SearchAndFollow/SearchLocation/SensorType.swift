// Created by Lunar on 12/04/2022.
//

import Foundation

enum SensorType: Codable, CaseIterable {
    case AirBeam
    case Govt
}

extension SensorType {
    var capitalizedName: String {
        switch self {
        case .AirBeam: return Strings.SearchFollowSensorNames.AirBeam3and2
        case .Govt: return Strings.SearchFollowSensorNames.Govt
        }
    }
}
