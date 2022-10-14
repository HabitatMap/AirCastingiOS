// Created by Lunar on 14/10/2022.
//

import Foundation
import DeviceKit

extension Device {
    static func excludedDevices(for feature: FeaturesProtocol) -> [Device] {
        feature.getDevicesList()
    }
}
