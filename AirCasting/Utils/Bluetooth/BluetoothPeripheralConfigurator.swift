// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothPeripheralConfigurator {
    func sendMessage(data: Data, to device: any BluetoothDevice, serviceID: String, characteristicID: String, completion: @escaping BluetoothManager.writingValueCallback) throws
}

extension BluetoothManager: BluetoothPeripheralConfigurator {}
