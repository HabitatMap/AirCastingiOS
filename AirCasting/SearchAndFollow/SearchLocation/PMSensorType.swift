// Created by Lunar on 12/04/2022.
//

import Foundation

enum PMSensorType: Codable, CaseIterable, Identifiable {
    case AB3and2
    case OpenAQ
    case PurpleAir
}

extension PMSensorType {
    var id: Self { self }
    
    var capitalizedName: String {
        switch self {
        case .AB3and2: return Strings.SearchFollowSensorNames.AirBeam3and2
        case .OpenAQ: return Strings.SearchFollowSensorNames.openAQ
        case .PurpleAir: return Strings.SearchFollowSensorNames.purpleAir
        }
    }
}
