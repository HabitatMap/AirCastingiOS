// Created by Lunar on 26/04/2022.
//

import Foundation

enum AirBeamStreamSuffixes: CaseIterable {
    case F
    case pm1
    case pm25
    case pm10
    case RH
    
    var capitalizedName: String {
        switch self {
        case .F: return "F"
        case .pm1: return "PM1"
        case .pm25: return "PM2.5"
        case .pm10: return "PM10"
        case .RH: return "RH"
        }
    }
}
