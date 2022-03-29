// Created by Lunar on 17/02/2022.
//

import Foundation

enum UnitSymbol: Codable {
    case uqm3
}

extension UnitSymbol {
    var name: String {
        switch self {
        case .uqm3: return "µg/m³"
        }
    }
}
