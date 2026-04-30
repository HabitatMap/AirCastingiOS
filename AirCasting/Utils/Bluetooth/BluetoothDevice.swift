// Created by Lunar on 05/12/2022.
//

import Foundation

protocol BluetoothDevice {
    var name: String? { get }
    var uuid: String { get }
    var firmwareVersion: FirmwareVersion { get }
}

extension BluetoothDevice {
    var firmwareVersion: FirmwareVersion { .v1 }
}

extension BluetoothDevice {
    var airbeamType: AirBeamDeviceType? {
        AirBeamDeviceType.allCases
            .first { self.name?.lowercased().contains($0.rawName) ?? false }
    }
}
