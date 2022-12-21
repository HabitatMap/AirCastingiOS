// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothConnectionHandler {
    func connect(to device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping BluetoothManager.ConnectionCallback) throws
    func disconnect(from device: any BluetoothDevice) throws
    func discoverCharacteristics(for device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping BluetoothManager.CharacteristicsDicoveryCallback) throws
}

extension BluetoothManager: BluetoothConnectionHandler {}
