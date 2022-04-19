// Created by Lunar on 12/04/2022.
//

import Foundation

enum MeasurementType: Codable, Identifiable, CaseIterable {
    case particulateMatter
    case ozone
}

extension MeasurementType {
    var id: Self { self }
    
    var capitalizedName: String {
        switch self {
        case .particulateMatter: return Strings.SearchFollowParamNames.particulateMatter
        case .ozone: return Strings.SearchFollowParamNames.ozone
        }
    }
}
