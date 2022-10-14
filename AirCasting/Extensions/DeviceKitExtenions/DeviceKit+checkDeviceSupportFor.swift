// Created by Lunar on 14/10/2022.
//

import Foundation
import DeviceKit

func checkDeviceSupportFor(feature: Features) -> Bool {
    let currentDevice = Device.current
    if currentDevice.isOneOf(Device.excludedDevices(for: feature)) {
        return false
    }
    return true
}
