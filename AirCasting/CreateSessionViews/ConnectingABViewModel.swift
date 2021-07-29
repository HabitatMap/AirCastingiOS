// Created by Lunar on 21/07/2021.
//

import CoreBluetooth
import Foundation

protocol BluetoothConnector {
    
}

class BluetoothABConnection: ConnectingAirBeamService {
    let bluetoothConnector: BluetoothConnector

    init(bluetoothConnector: BluetoothConnector) {
        self.bluetoothConnector = bluetoothConnector
    }
}

// connectingABServices
protocol ConnectingAirBeamService {
    
}

class ABConnector: AirBeamConnector {
    let connectingABServices: ConnectingAirBeamService
    func performConnectingWithin10Second(peripheral: CBPeripheral, completion: @escaping () -> Void) {
//        bluetoothManager.centralManager.connect(peripheral, options: nil)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [self] in
//            if peripheral.state == .connecting {
//                Log.info("Connecting to bluetooth device failed")
//                self.bluetoothManager.centralManager.cancelPeripheralConnection(peripheral)
//                completion()
//            }
//        }
    }
    
    init(connectingABServices: ConnectingAirBeamService) {
        self.connectingABServices = connectingABServices
    }
}

// connectingABProtocol
protocol AirBeamConnector {
    func performConnectingWithin10Second(peripheral: CBPeripheral, completion: @escaping () -> Void)
}


// NOT FOR NOW
class ConnectingABViewModel: AirBeamConnector {
    func performConnectingWithin10Second(peripheral: CBPeripheral, completion: @escaping () -> Void) {
        completion()
    }
}
