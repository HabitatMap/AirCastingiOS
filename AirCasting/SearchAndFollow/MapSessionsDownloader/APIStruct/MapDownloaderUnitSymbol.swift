// Created by Lunar on 17/02/2022.
//

import Foundation

enum MapDownloaderUnitSymbol: Codable {
    case uqm3
    case ppb
}

extension MapDownloaderUnitSymbol {
    var name: String {
        switch self {
        case .uqm3: return "µg/m³"
        case .ppb: return "ppb"
        }
    }
}
