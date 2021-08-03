// Created by Lunar on 30/07/2021.
//

import CoreBluetooth
import Foundation

enum AirBeamServicesConnectionResult {
    case success
    case timeout
    case deviceBusy
}

protocol ConnectingAirBeamServices {
    func connect(to peripheral: CBPeripheral, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void)
}

class ConnectingAirBeamServicesBluetooth: ConnectingAirBeamServices {
    private var connectionInProgress = false
    private let bluetoothConnector: BluetoothConnector
    private var connectionToken: AnyObject?

    init(bluetoothConnector: BluetoothConnector) {
        self.bluetoothConnector = bluetoothConnector
    }

    func connect(to peripheral: CBPeripheral, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        guard !connectionInProgress else { completion(.deviceBusy); return }
        bluetoothConnector.connect(to: peripheral)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(timeout))) {
            if peripheral.state == .connecting {
                Log.info("Connecting to bluetooth device failed")
                self.bluetoothConnector.cancelPeripheralConnection(for: peripheral)
                completion(.timeout)
            }
        }
        connectionToken = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "DeviceConnected"), object: nil, queue: nil) { [connectionToken] _ in
            completion(.success)
            guard let token = connectionToken else { return }
            NotificationCenter.default.removeObserver(token)
        }
    }
}
