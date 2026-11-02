// Created by Lunar on 05/12/2022.
//

import Foundation

protocol BluetoothDevice {
    var name: String? { get }
    var uuid: String { get }
    var firmwareVersion: FirmwareVersion { get }
    /// Base MAC / device ID parsed out of the advertised local name without colons
    /// (e.g. `"24587CACA6B4"` from old V2 `AirBeamMini:24:58:7C:AC:A6:B6` after `-2`
    /// adjustment, or directly from new V2 `AirBeamMini:24587CACA6B4`). `nil` if the
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
