// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothConnectionHandler {
    func connect(to device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping BluetoothManager.ConnectionCallback) throws
    func disconnect(from device: any BluetoothDevice) throws
    func discoverCharacteristics(for device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping BluetoothManager.CharacteristicsDicoveryCallback) throws
    /// Returns the device with its `firmwareVersion` re-resolved from the live
    /// per-peripheral GATT/advert state, which can differ from a `BluetoothDevice`
    /// snapshot taken earlier. After a process restart the in-memory firmware
    /// cache is empty and a reconnecting peripheral defaults to `.v1`; GATT
    /// service discovery then re-stamps the true version. Reconnect must branch
    /// on this refreshed value, not the stale snapshot — branching on the snapshot
    /// routed a v2 AirBeam into the v1 configurator (wrong-service lookup → silent
    /// hang → "AB connected / app disconnected"). Returns the input device
    /// unchanged when it is not a managed peripheral or the version is unchanged.
    func refreshedDevice(for device: any BluetoothDevice) -> any BluetoothDevice
}

extension BluetoothManager: BluetoothConnectionHandler {}
