// Created by Lunar on 31/10/2022.
//

import Foundation
import DeviceKit

class DeviceFeatureFlagProvider: FeatureFlagProvider {
    var onFeatureListChange: (() -> Void)?
    
    func isFeatureOn(_ feature: FeatureFlag) -> Bool? {
        // Here we would like to block only the availability of some features based on the current device.
        // Returning false here overrides all the other `FeatureFlags`.
        // The purpose of returning nil here and never true is to use the next available `FeatureFlagProvider`.
        guard Device.current == .iPhoneSE || Device.current == .simulator(.iPhoneSE) else { return nil }
        switch feature {
        case .sdCardSync:
            return false
        case .standaloneMode:
            return false
        default:
            return nil
        }
    }
}
