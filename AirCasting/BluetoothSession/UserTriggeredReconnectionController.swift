// Created by Lunar on 24/11/2022.
//

import Foundation
import Resolver

enum UserTriggeredReconnectionError: Error {
    case anotherActiveSessionInProgress
    case failedToConnect
    case deviceNotDiscovered
}

protocol UserTriggeredReconnectionController {
    func reconnectWithPeripheral(deviceUUID: String, session: Session, completion: @escaping (Result<Void, UserTriggeredReconnectionError>) -> Void)
}

class DefaultUserTriggeredReconnectionController: UserTriggeredReconnectionController {
    @Injected private var btScanner: BluetoothScanner
    @Injected private var bluetootConnector: BluetoothConnectionHandler
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var sessionRecorder: BluetoothSessionRecordingController
    
    func reconnectWithPeripheral(deviceUUID: String, session: Session, completion: @escaping (Result<Void, UserTriggeredReconnectionError>) -> Void) {
        guard activeSessionProvider.activeSession == nil else {
            Log.info("Tried to resume session when there was another active session in progress")
            completion(.failure(.anotherActiveSessionInProgress))
            return
        }
        
        var discoveredDevices: [NewBluetoothManager.BluetoothDevice] = []
        btScanner.startScanning(scanningWindow: 5, onDeviceDiscovered: { discoveredDevices.append($0) }, onScanningFinished: { [weak self] in
            guard let device = discoveredDevices.first(where: { $0.uuid == deviceUUID }) else {
                completion(.failure(.deviceNotDiscovered))
                return
            }
            
            self?.connect(to: device, session: session) { result in
                switch result {
                case .success():
                    self?.resume(session, device: device, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        })
    }
    
    private func connect(to device: NewBluetoothManager.BluetoothDevice, session: Session, completion: @escaping (Result<Void, UserTriggeredReconnectionError>) -> Void) {
        bluetootConnector.connect(to: device, timeout: 10) {[weak self] result in
            switch result {
            case .success:
                Log.info("Reconnected to a peripheral: \(String(describing: device.name))")
                self?.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { result in
                    switch result {
                    case .success:
                        Log.info("Discovered characteristics for: \(String(describing: device.name))")
                        completion(.success(()))
                    case .failure(_):
                        Log.info("Faile to discover characteristics for: \(String(describing: device.name))")
                        completion(.failure(.failedToConnect))
                    }
                }
            case .failure(_):
                completion(.failure(.failedToConnect))
            }
        }
    }
    
    private func resume(_ session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, UserTriggeredReconnectionError>) -> Void) {
        activeSessionProvider.setActiveSession(session: session, device: device)
        sessionRecorder.resumeRecording(device: device) { result in
            switch result {
            case .success():
                completion(.success(()))
            case .failure(let error):
                Log.error("Failed to resume recording: \(error)")
                completion(.failure(.failedToConnect))
            }
        }
    }
}
