// Created by Lunar on 05/12/2021.
//

import Foundation

// Precaution for zero-division
extension Optional where Wrapped == Int {
    var orOne: Int {
        switch self {
        case .none: return 1
        default: return self!.orOne
        }
    }
}

extension Int {
    var orOne: Int {
        guard self != 0 else { return 1 }
        return self
    }
}
