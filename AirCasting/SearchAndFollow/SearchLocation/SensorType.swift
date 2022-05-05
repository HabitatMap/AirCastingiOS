// Created by Lunar on 12/04/2022.
//

import Foundation

enum SensorType: Codable, CaseIterable {
    case AB3and2
    case OpenAQ
    case PurpleAir
}

extension SensorType {
    
    var capitalizedName: String {
        switch self {
        case .AB3and2: return Strings.SearchFollowSensorNames.AirBeam3and2
        case .OpenAQ: return Strings.SearchFollowSensorNames.openAQ
        case .PurpleAir: return Strings.SearchFollowSensorNames.purpleAir
        }
    }
}
