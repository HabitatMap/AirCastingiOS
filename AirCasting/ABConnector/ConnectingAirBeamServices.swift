// Created by Lunar on 30/07/2021.
//

import Foundation
import CoreBluetooth

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
    
    private let bluetoothConnector: BluetoothConnector
    private var connectionToken: AnyObject?
    
    init(bluetoothConnector: BluetoothConnector) {
        self.bluetoothConnector = bluetoothConnector
    }

    func connect(to peripheral: CBPeripheral, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        var connectionInProgress = true
        Log.info("Starting Airbeam connection")
        guard !(peripheral.state == .connecting) else {
            completion(.deviceBusy); return
        }
        bluetoothConnector.connect(to: peripheral)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(timeout))) {
            if connectionInProgress {
                Log.info("Airbeam connection failed")
                self.bluetoothConnector.cancelPeripheralConnection(for: peripheral)
                completion(.timeout)
                NotificationCenter.default.removeObserver(self.connectionToken)
            }
        }
        connectionToken = NotificationCenter.default.addObserver(forName: .deviceConnected, object: nil, queue: nil) { _ in
            Log.info("Airebeam connected successfully")
            var characteristicsHandle: Any?
            NotificationCenter.default.removeObserver(self.connectionToken)
            characteristicsHandle = NotificationCenter.default.addObserver(forName: .discoveredCharacteristic, object: nil, queue: .main) { notification in
                guard notification.userInfo?[AirCastingNotificationKeys.DiscoveredCharacteristic.peripheralUUID] as! UUID == peripheral.identifier else { return }
                connectionInProgress = false
                completion(.success)
                guard let characteristicsHandle = characteristicsHandle else { return }
                NotificationCenter.default.removeObserver(characteristicsHandle)
            }
        }
    }
    
    func disconnect(from peripheral: CBPeripheral) {
        bluetoothConnector.cancelPeripheralConnection(for: peripheral)
    }
}
