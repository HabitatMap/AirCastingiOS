// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothConnectionHandler {
    func connect(to device: NewBluetoothManager.BluetoothDevice, timeout: TimeInterval, completion: @escaping NewBluetoothManager.ConnectionCallback)
    func disconnect(from device: NewBluetoothManager.BluetoothDevice)
    func discoverCharacteristics(for device: NewBluetoothManager.BluetoothDevice, timeout: TimeInterval, completion: @escaping NewBluetoothManager.CharacteristicsDicoveryCallback)
}

extension NewBluetoothManager: BluetoothConnectionHandler {}
