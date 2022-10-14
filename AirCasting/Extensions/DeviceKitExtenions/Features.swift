// Created by Lunar on 14/10/2022.
//

import Foundation
import DeviceKit

protocol FeaturesProtocol {
    func getDevicesList() -> [Device]
}

enum Features: FeaturesProtocol {
    case sync
    case standalone
    
    func getDevicesList() -> [Device] {
        switch self {
        case .sync:
            return [.iPhoneSE]
        case .standalone:
            return [.iPhoneSE]
        }
    }
}
