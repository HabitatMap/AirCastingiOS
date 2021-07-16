// Created by Lunar on 14/07/2021.
//

import Foundation

enum LocationSates {
    case granted
    case denied
    
    var isAllowed: Bool {
        switch self {
        case .granted: return true
        case .denied: return false
        }
    }
}
