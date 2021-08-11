// Created by Lunar on 04/08/2021.
//

import Foundation
import CoreBluetooth

protocol BluetoothHandler {
    func isBluetoothDenied() -> Bool
}

class DefaultBluetoothHandler: BluetoothHandler {
    
    var bluetoothManager: BluetoothManager
    
    var bluetoothManagerState: CBManagerState {
        return bluetoothManager.centralManagerState
    }
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
    
    func isBluetoothDenied() -> Bool {
        CBCentralManager.authorization == .denied ? true : false
    }
}

#if DEBUG
class DummyDefaultBluetoothHandler: BluetoothHandler {
    var bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    
    var bluetoothManagerState: CBManagerState = .unauthorized
    
    func isBluetoothDenied() -> Bool {
        return true
    }
}
#endif
