// Created by Lunar on 31/10/2022.
//

import Foundation
import DeviceKit

class DeviceFeatureFlagProvider: FeatureFlagProvider {
    var onFeatureListChange: (() -> Void)?
    
    func isFeatureOn(_ feature: FeatureFlag) -> Bool? {
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
