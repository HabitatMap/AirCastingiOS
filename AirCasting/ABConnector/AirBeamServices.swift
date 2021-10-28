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
}

class ConnectingAirBeamServicesBluetooth: ConnectingAirBeamServices {
    
    private(set) var connectionInProgress = false
    private let bluetoothConnector: BluetoothConnector
    private var connectionToken: AnyObject?
    
    init(bluetoothConnector: BluetoothConnector) {
        self.bluetoothConnector = bluetoothConnector
        Log.info("##Initialised")
    }

    func connect(to peripheral: CBPeripheral, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        Log.info("Starting Airbeam connection")
        Log.info("##Starting Airbeam connection")
        guard !connectionInProgress else {
            completion(.deviceBusy); return
        }
        bluetoothConnector.connect(to: peripheral)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(timeout))) {
            if peripheral.state == .connecting {
                Log.info("Airbeam connection failed")
                self.bluetoothConnector.cancelPeripheralConnection(for: peripheral)
                completion(.timeout)
            }
        }
        connectionToken = NotificationCenter.default.addObserver(forName: .deviceConnected, object: nil, queue: nil) { _ in
            Log.info("##Airebeam connected successfully")
            self.connectionInProgress = false
            var characteristicsHandle: Any?
            characteristicsHandle = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Discovered characteristics"), object: nil, queue: .main) { [weak self] _ in
                Log.info("##Discovered characteristic")
                completion(.success)
                guard let contextHandle = characteristicsHandle else { return }
                NotificationCenter.default.removeObserver(contextHandle)
            }
        }
    }
}
