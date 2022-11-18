// Created by Lunar on 17/11/2022.
//

import Foundation

protocol BluetoothPeripheralConnectionChecker {
    func isDeviceConnected(device: NewBluetoothManager.BluetoothDevice) -> Bool
}

extension NewBluetoothManager: BluetoothPeripheralConnectionChecker {}
