// Created by Lunar on 27/10/2021.
//

import Foundation

extension Notification.Name {
    static let deviceConnected = Notification.Name(rawValue: "DeviceConnected")
}

enum AirCastingNotificationKeys {
    enum DeviceConnected {
        static let uuid = "uuid"
    }
}
