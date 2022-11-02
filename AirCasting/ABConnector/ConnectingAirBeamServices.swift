// Created by Lunar on 30/07/2021.
//

import Foundation
import Resolver

enum AirBeamServicesConnectionResult {
    case success
    case timeout
    case deviceBusy
}

protocol ConnectingAirBeamServices {
    func connect(to device: NewBluetoothManager.BluetoothDevice, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void)
    func disconnect(from device: NewBluetoothManager.BluetoothDevice)
}

class ConnectingAirBeamServicesBluetooth: ConnectingAirBeamServices {
    @Injected private var btManager: NewBluetoothManager
    private var connectionToken: AnyObject?

    func connect(to device: NewBluetoothManager.BluetoothDevice, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        Log.info("Starting Airbeam connection")
        
        // TODO: CHANGE THIS
        guard !(device.peripheral.state == .connecting) else {
            completion(.deviceBusy); return
        }
        
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
    
    func disconnect(from device: NewBluetoothManager.BluetoothDevice) {
        btManager.disconnect(from: device)
    }
}
