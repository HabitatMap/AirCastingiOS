// Created by Lunar on 05/12/2022.
//

import Foundation

protocol BluetoothDevice {
    var name: String? { get }
    var uuid: String { get }
    var firmwareVersion: FirmwareVersion { get }
    /// Real BLE MAC parsed out of the advertised local name (e.g. `AirBeamMini:A23456789E`,
    /// or normalized with -2 from V2 1.0.0 `AirBeamMini:A2:34:56:78:A1`). `nil` if the
    /// advertisement has not yet surfaced a MAC. iOS itself never exposes the
    /// raw BLE MAC; this is the only path to it.
    var realMacAddress: String? { get }
}

extension BluetoothDevice {
    var firmwareVersion: FirmwareVersion { .v1 }
    var realMacAddress: String? { nil }
}

extension BluetoothDevice {
    var airbeamType: AirBeamDeviceType? {
        AirBeamDeviceType.allCases
            .first { self.name?.lowercased().contains($0.rawName) ?? false }
    }
}
