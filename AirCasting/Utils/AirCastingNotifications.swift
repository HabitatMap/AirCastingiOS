// Created by Lunar on 27/10/2021.
//

import Foundation

extension Notification.Name {
    static let deviceConnected = Notification.Name(rawValue: "DeviceConnected")
    static let discoveredCharacteristic = Notification.Name(rawValue: "DiscoveredCharacteristic")
    /// Posted by the V2 mobile session path after a live PM measurement is persisted,
    /// so live-graph and active session views can refresh.
    static let v2MeasurementSaved = Notification.Name(rawValue: "V2MeasurementSaved")
}

enum AirCastingNotificationKeys {
    enum DeviceConnected {
        static let uuid = "uuid"
    }

    enum DiscoveredCharacteristic {
        static let peripheralUUID = "peripheral uuid"
    }

    enum V2MeasurementSaved {
        static let sessionUUID = "sessionUUID"
    }
}
