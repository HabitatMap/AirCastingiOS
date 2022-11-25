// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothPeripheralConfigurator {
    func sendMessage(data: Data, to device: NewBluetoothManager.BluetoothDevice, serviceID: String, characteristicID: String, completion: @escaping NewBluetoothManager.writingValueCallback)
}

extension NewBluetoothManager: BluetoothPeripheralConfigurator {}
