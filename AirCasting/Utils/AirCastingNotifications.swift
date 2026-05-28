// Created by Lunar on 27/10/2021.
//

import Foundation

extension Notification.Name {
    static let deviceConnected = Notification.Name(rawValue: "DeviceConnected")
    static let discoveredCharacteristic = Notification.Name(rawValue: "DiscoveredCharacteristic")
    /// Posted by the V2 mobile session path after a live PM measurement is persisted,
    /// so live-graph and active session views can refresh.
    static let v2MeasurementSaved = Notification.Name(rawValue: "V2MeasurementSaved")
    /// Posted when V2 active-sync drain state flips (Sync indications arriving / 3 s idle).
    /// Phase 6 finish-flow gates the drain-aware dialog on this signal.
    static let v2SyncDrainChanged = Notification.Name(rawValue: "V2SyncDrainChanged")
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

    enum V2SyncDrainChanged {
        static let deviceUUID = "deviceUUID"
        static let isDraining = "isDraining"
    }
}
