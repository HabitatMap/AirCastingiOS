// Created by Lunar on 30/07/2021.
//

import Foundation
import CoreBluetooth

protocol BluetoothConnector {
    func connect(to peripheral: CBPeripheral)
    func cancelPeripheralConnection(for peripheral: CBPeripheral)
}
