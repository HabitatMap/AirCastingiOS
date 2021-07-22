// Created by Lunar on 21/07/2021.
//

import CoreBluetooth
import Foundation

protocol AirBeamConnector {
    func performConnectingWithin10Second(peripheral: CBPeripheral, completion: @escaping () -> Void)
}

class ConnectingABViewModel: AirBeamConnector {
    var bluetoothManager: BluetoothManager
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
    
    func performConnectingWithin10Second(peripheral: CBPeripheral, completion: @escaping () -> Void) {
        bluetoothManager.centralManager.connect(peripheral, options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [self] in
            if peripheral.state == .connecting {
                Log.info("Connecting to bluetooth device failed")
                self.bluetoothManager.centralManager.cancelPeripheralConnection(peripheral)
                completion()
            }
        }
    }
}
