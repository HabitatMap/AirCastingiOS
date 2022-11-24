// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver

protocol ReconnectionControllerDelegate: AnyObject {
    func shouldReconnect(to device: NewBluetoothManager.BluetoothDevice) -> Bool
    func didReconnect(to device: NewBluetoothManager.BluetoothDevice)
    func didFailToReconnect(to device: NewBluetoothManager.BluetoothDevice)
}

protocol ReconnectionController {
    var delegate: ReconnectionControllerDelegate? { get set }
}

class DefaultReconnectionObserver: ReconnectionController, BluetoothConnectionObserver {
    weak var delegate: ReconnectionControllerDelegate?
    @Injected private var bluetoothManager: BluetoothConnectionObservable
    @Injected private var bluetootConnector: BluetoothConnectionHandler
    
    init() {
        bluetoothManager.addConnectionObserver(self)
    }
    
    deinit {
        bluetoothManager.removeConnectionObserver(self)
    }
    
    func didDisconnect(device: NewBluetoothManager.BluetoothDevice) {
        guard delegate?.shouldReconnect(to: device) ?? false else { return }
        
        bluetootConnector.connect(to: device, timeout: 10) { result in
            switch result {
            case .success:
                Log.info("Reconnected to a peripheral: \(device)")
                self.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { result in
                    switch result {
                    case .success:
                        Log.info("Discovered characteristics for: \(device)")
                        self.delegate?.didReconnect(to: device)
                    case .failure(_):
                        self.delegate?.didFailToReconnect(to: device)
                    }
                }
            case .failure(_):
                self.delegate?.didFailToReconnect(to: device)
            }
        }
    }
}


class UserTriggeredReconnectionController {
    @Injected private var btScanner: BluetoothScanner
    @Injected private var bluetootConnector: BluetoothConnectionHandler
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    
    enum UserTroggeredReconnectionError: Error {
        case anotherActiveSessionInProgress
        case failedToDiscoverCharacteristics
        case failedToConnect
        case deviceNotDiscovered
    }
    
    func reconnectWithPeripheral(deviceUUID: String, completion: @escaping (Result<NewBluetoothManager.BluetoothDevice, Error>) -> Void) {
        guard activeSessionProvider.activeSession == nil else {
            Log.info("Tried to resume session when there was another active session in progress")
            completion(.failure(UserTroggeredReconnectionError.anotherActiveSessionInProgress))
            return
        }
        var discoveredDevices: [NewBluetoothManager.BluetoothDevice] = []
        btScanner.startScanning(scanningWindow: 10, onDeviceDiscovered: { discoveredDevices.append($0) }, onScanningFinished: {
            guard let device = discoveredDevices.first(where: { $0.uuid == deviceUUID }) else {
                completion(.failure(UserTroggeredReconnectionError.deviceNotDiscovered))
                return
            }
            
            self.bluetootConnector.connect(to: device, timeout: 10) { result in
                switch result {
                case .success:
                    Log.info("Reconnected to a peripheral: \(device)")
                    self.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { result in
                        switch result {
                        case .success:
                            Log.info("Discovered characteristics for: \(device)")
                            completion(.success((device)))
                        case .failure(_):
                            completion(.failure(UserTroggeredReconnectionError.failedToDiscoverCharacteristics))
                        }
                    }
                case .failure(_):
                    completion(.failure(UserTroggeredReconnectionError.failedToConnect))
                }
            }
        })
    }
}
