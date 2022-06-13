// Created by Lunar on 28/04/2022.
//

import Foundation

enum AirBeamStreamPrefix: CaseIterable {
    case airBeam2
    case airBeam3
    
    var rawName: String {
        switch self {
        case .airBeam2: return "airbeam2"
        case .airBeam3: return "airbeam3"
        }
    }
    
    var userFacingName: String {
        switch self {
        case .airBeam2: return "AirBeam2"
        case .airBeam3: return "AirBeam3"
        }
    }
}

