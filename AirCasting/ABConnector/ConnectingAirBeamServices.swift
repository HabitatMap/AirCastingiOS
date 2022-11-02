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
                    switch result {
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
        
//        bluetoothConnector.connect(to: peripheral)
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(timeout))) {
//            if connectionInProgress {
//                Log.info("Airbeam connection failed")
//                self.bluetoothConnector.cancelPeripheralConnection(for: peripheral)
//                completion(.timeout)
//                NotificationCenter.default.removeObserver(self.connectionToken as AnyObject)
//            }
//        }
//        connectionToken = NotificationCenter.default.addObserver(forName: .deviceConnected, object: nil, queue: nil) { _ in
//            Log.info("Airebeam connected successfully")
//            var characteristicsHandle: Any?
//            NotificationCenter.default.removeObserver(self.connectionToken as AnyObject)
//            //
//            // Move from NotificationCenter -> BluetoothCommunicator
//            //
//            // func subscribeToCharacteristic(_ characteristic: CBUUID, timeout: TimeInterval?, notify: @escaping CharacteristicObserverAction) -> AnyHashable
//            //
//            characteristicsHandle = NotificationCenter.default.addObserver(forName: .discoveredCharacteristic, object: nil, queue: .main) { notification in
//                guard notification.userInfo?[AirCastingNotificationKeys.DiscoveredCharacteristic.peripheralUUID] as! UUID == peripheral.identifier else { return }
//                connectionInProgress = false
//                completion(.success)
//                guard let characteristicsHandle = characteristicsHandle else { return }
//                NotificationCenter.default.removeObserver(characteristicsHandle)
//            }
//        }
    }
    
    func disconnect(from peripheral: CBPeripheral) {
        bluetoothConnector.cancelPeripheralConnection(for: peripheral)
    }
}
