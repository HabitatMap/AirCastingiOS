// Created by Lunar on 14/10/2022.
//

import Foundation
import DeviceKit

protocol FeaturesProtocol {
    func getExcludedDevicesList() -> [Device]
}

enum Features: FeaturesProtocol {
    case sync
    case standalone
    
    func getExcludedDevicesList() -> [Device] {
        switch self {
        case .sync:
            return [.iPhoneSE,
                    .simulator(.iPhoneSE)]
        case .standalone:
            return [.iPhoneSE,
                    .simulator(.iPhoneSE)]
        }
    }
}
