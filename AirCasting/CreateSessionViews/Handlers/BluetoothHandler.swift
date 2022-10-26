// Created by Lunar on 04/08/2021.
//

import Foundation
import CoreBluetooth
import Resolver

protocol BluetoothHandler {
    func isBluetoothDenied() -> Bool
}

class DefaultBluetoothHandler: BluetoothHandler {
    @Injected private var bluetoothManager: BluetoothManager
    
    func isBluetoothDenied() -> Bool {
        CBCentralManager.authorization != .allowedAlways || bluetoothManager.deviceState != .poweredOn
    }
}
