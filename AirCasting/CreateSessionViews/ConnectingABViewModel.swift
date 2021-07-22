// Created by Lunar on 21/07/2021.
//

import CoreBluetooth
import Foundation

protocol AirBeamConnector {
    func performConnectionWithin10Second(peripheral: CBPeripheral, completion: @escaping () -> Void)
}

protocol BluetoothConnector {
    func connectWithDevice(peripheral: CBPeripheral)
    func cancelConnectionWithDevice(peripheral: CBPeripheral)
}

class DefaultBluetoothConnector {
    var bluetoothManager: BluetoothManager
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
}

class BluetoothAirBeamConnection: DefaultBluetoothConnector, BluetoothConnector {
    func connectWithDevice(peripheral: CBPeripheral) {
        bluetoothManager.centralManager.connect(peripheral, options: nil)
    }
    func cancelConnectionWithDevice(peripheral: CBPeripheral) {
        bluetoothManager.centralManager.cancelPeripheralConnection(peripheral)
    }
}

class DefaultAirBeamConnector: BluetoothAirBeamConnection, AirBeamConnector {
    func performConnectionWithin10Second(peripheral: CBPeripheral, completion: @escaping () -> Void) {
      connectWithDevice(peripheral: peripheral)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [self] in
            if peripheral.state == .connecting {
                Log.info("Connecting to bluetooth device failed")
                cancelConnectionWithDevice(peripheral: peripheral)
                completion()
            }
        }
    }
}
