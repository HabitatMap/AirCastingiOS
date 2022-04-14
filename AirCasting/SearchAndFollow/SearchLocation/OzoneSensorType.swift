// Created by Lunar on 12/04/2022.
//

import Foundation

enum OzoneSensorType: Codable, CaseIterable, Identifiable {
    case OzoneSensor
}

extension OzoneSensorType {
    var id: Self { self }
    
    var capitalizedName: String {
        switch self {
        case .OzoneSensor: return Strings.SearchFollowSensorNames.openAQOzone
        }
    }
}
