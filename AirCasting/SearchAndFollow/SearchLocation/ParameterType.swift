// Created by Lunar on 12/04/2022.
//

import Foundation

enum ParameterType: Codable, Identifiable, CaseIterable {
    case particulateMatter
    case ozone
}

extension ParameterType {
    var id: Self { self }
    
    var capitalizedName: String {
        switch self {
        case .particulateMatter: return Strings.SearchFollowParamNames.particulateMatter
        case .ozone: return Strings.SearchFollowParamNames.ozone
        }
    }
}
