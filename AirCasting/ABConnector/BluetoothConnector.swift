// Created by Lunar on 30/07/2021.
//

import Foundation
import CoreBluetooth

protocol BluetoothConnector {
    func connect(to peripheral: CBPeripheral)
    func cancelPeripheralConnection(for peripheral: CBPeripheral)
}

extension BluetoothManager: BluetoothConnector {
    
    func connect(to peripheral: CBPeripheral) {
        Log.info("Starting Airbeam connection")
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func cancelPeripheralConnection(for peripheral: CBPeripheral) {
        self.centralManager.cancelPeripheralConnection(peripheral)
    }
}
