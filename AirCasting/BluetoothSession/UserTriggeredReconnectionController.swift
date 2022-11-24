// Created by Lunar on 24/11/2022.
//

import Foundation
import Resolver

enum UserTroggeredReconnectionError: Error {
    case anotherActiveSessionInProgress
    case failedToDiscoverCharacteristics
    case failedToConnect
    case deviceNotDiscovered
    case airbeamConfigurationFailure
}

protocol UserTriggeredReconnectionController {
    func reconnectWithPeripheral(deviceUUID: String, session: Session, completion: @escaping (Result<Void, UserTroggeredReconnectionError>) -> Void)
}

class DefaultUserTriggeredReconnectionController: UserTriggeredReconnectionController {
    @Injected private var btScanner: BluetoothScanner
    @Injected private var bluetootConnector: BluetoothConnectionHandler
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var sessionRecorder: BluetoothSessionRecordingController
    
    func reconnectWithPeripheral(deviceUUID: String, session: Session, completion: @escaping (Result<Void, UserTroggeredReconnectionError>) -> Void) {
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
                            self.activeSessionProvider.setActiveSession(session: session, device: device)
                            self.sessionRecorder.resumeRecording(device: device) { result in
                                switch result {
                                case .success():
                                    completion(.success(()))
                                case .failure(let error):
                                    Log.error("Failed to resume recording: \(error)")
                                    completion(.failure(.airbeamConfigurationFailure))
                                }
                            }
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
