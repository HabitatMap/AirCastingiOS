// Created by Lunar on 12/04/2022.
//

import Foundation

enum MeasurementType: Codable, CaseIterable {
    case particulateMatter
    case ozone
    case nitrogenDioxide
}

extension MeasurementType {
    
    var capitalizedName: String {
        switch self {
        case .particulateMatter: return Strings.SearchFollowParamNames.particulateMatter
        case .ozone: return Strings.SearchFollowParamNames.ozone
        case .nitrogenDioxide: return Strings.SearchFollowParamNames.nitrogenDioxide
        }
    }
}
