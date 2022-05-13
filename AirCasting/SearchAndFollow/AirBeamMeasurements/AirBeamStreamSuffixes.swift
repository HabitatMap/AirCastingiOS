// Created by Lunar on 26/04/2022.
//

import Foundation

enum AirBeamStreamSuffixes: CaseIterable {
    case F
    case pm1
    case pm25
    case pm10
    case RH
    
    var rawName: String {
        switch self {
        case .F: return "f"
        case .pm1: return "pm1"
        case .pm25: return "pm2.5"
        case .pm10: return "pm10"
        case .RH: return "rh"
        }
    }
}
