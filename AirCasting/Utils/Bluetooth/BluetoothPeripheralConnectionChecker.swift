// Created by Lunar on 17/11/2022.
//

import Foundation

protocol BluetoothPeripheralConnectionChecker {
    func isDeviceConnected(device: any BluetoothDevice) throws -> Bool
}

extension BluetoothManager: BluetoothPeripheralConnectionChecker {}
