// Created by Lunar on 30/07/2021.
//

import Foundation
import CoreBluetooth

protocol BluetoothConnector {
    var isDeviceConnected: Bool { get }
    func connect(to peripheral: CBPeripheral)
    func cancelPeripheralConnection(for peripheral: CBPeripheral)
}

extension BluetoothManager: BluetoothConnector {
    var isDeviceConnected: Bool {
        isConnected
    }
    
    func connect(to peripheral: CBPeripheral) {
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func cancelPeripheralConnection(for peripheral: CBPeripheral) {
        self.centralManager.cancelPeripheralConnection(peripheral)
    }
}
