// Created by Lunar on 30/07/2021.
//

import Foundation
import CoreBluetooth
import Resolver

enum AirBeamServicesConnectionResult {
    case success
    case timeout
    case deviceBusy
}

protocol ConnectingAirBeamServices {
    func connect(to peripheral: CBPeripheral, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void)
    func disconnect(from peripheral: CBPeripheral)
}

class ConnectingAirBeamServicesBluetooth: ConnectingAirBeamServices {
    @Injected private var bluetoothConnector: BluetoothConnector
    @Injected private var btManager: NewBluetoothManager
    private var connectionToken: AnyObject?

    func connect(to peripheral: CBPeripheral, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        Log.info("Starting Airbeam connection")
        guard !(peripheral.state == .connecting) else {
            completion(.deviceBusy); return
        }
        let device = NewBluetoothManager.BluetoothDevice(peripheral: peripheral)
        btManager.connect(to: device, timeout: timeout) { result in
            switch result {
            case .success:
                self.btManager.discoverCharacteristics(for: device, timeout: timeout) { characteristicsResult in
                    switch characteristicsResult {
                    case .success:
                        completion(.success)
                    case .failure(let error):
                        Log.error("Failed to discover characteristics: \(error)")
                        completion(.timeout)
                    }
                }
            case .failure(let error):
                Log.error("Failed to connect to peripheral: \(error)")
                completion(.timeout)
            }
        }
    }
    
    func disconnect(from peripheral: CBPeripheral) {
        let device = NewBluetoothManager.BluetoothDevice(peripheral: peripheral)
        btManager.disconnect(from: device)
    }
}
