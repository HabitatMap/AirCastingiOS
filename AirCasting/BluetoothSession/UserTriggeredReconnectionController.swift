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
    @Injected private var reconnectionController: ReconnectionController

    func reconnectWithPeripheral(deviceUUID: String, session: Session, completion: @escaping (Result<Void, UserTriggeredReconnectionError>) -> Void) {
        // Branch A — active session still owns the device (auto-retry chain may
        // be in flight after a disconnect). Cancel the chain, reuse the cached
        // BluetoothDevice, run one immediate connect attempt. No scan needed.
        if let active = activeSessionProvider.activeSession,
           active.device.uuid == deviceUUID {
            Log.info("Manual reconnect requested; cancelling auto-retry chain and connecting directly to \(deviceUUID)")
            reconnectionController.cancelReconnect(deviceUUID: deviceUUID)
            connect(to: active.device, session: session) { [weak self] result in
                switch result {
                case .success():
                    self?.sessionRecorder.resumeRecording(device: active.device) { resumeResult in
                        switch resumeResult {
                        case .success(): completion(.success(()))
                        case .failure(let error):
                            Log.error("Manual reconnect: resumeRecording failed: \(error)")
                            completion(.failure(.failedToConnect))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }

        // Branch B — no active session (auto-retry exhausted, moved to
        // standalone). Scan, connect, set active session, resume.
        guard activeSessionProvider.activeSession == nil else {
            Log.info("Tried to resume session when there was another active session in progress")
            completion(.failure(.anotherActiveSessionInProgress))
            return
        }

        var discoveredDevices: [any BluetoothDevice] = []
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
    
    private func connect(to device: any BluetoothDevice, session: Session, completion: @escaping (Result<Void, UserTriggeredReconnectionError>) -> Void) {
        do {
            try bluetootConnector.connect(to: device, timeout: 10) {[weak self] result in
                switch result {
                case .success:
                    Log.info("Reconnected to a peripheral: \(String(describing: device.name))")
                    do {
                        try self?.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { result in
                            switch result {
                            case .success:
                                Log.info("Discovered characteristics for: \(String(describing: device.name))")
                                completion(.success(()))
                            case .failure(_):
                                Log.info("Faile to discover characteristics for: \(String(describing: device.name))")
                                completion(.failure(.failedToConnect))
                            }
                        }
                    } catch {
                        completion(.failure(.failedToConnect))
                    }
                case .failure(_):
                    completion(.failure(.failedToConnect))
                }
            }
        } catch {
            completion(.failure(.failedToConnect))
        }
    }
    
    private func resume(_ session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, UserTriggeredReconnectionError>) -> Void) {
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
