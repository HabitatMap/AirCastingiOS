// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver

protocol ReconnectionControllerDelegate: AnyObject {
    func shouldReconnect(to device: any BluetoothDevice) -> Bool
    func didReconnect(to device: any BluetoothDevice)
    func didFailToReconnect(to device: any BluetoothDevice)
}

protocol ReconnectionController {
    var delegate: ReconnectionControllerDelegate? { get set }
}

class DefaultReconnectionController: ReconnectionController, BluetoothConnectionObserver {
    weak var delegate: ReconnectionControllerDelegate?
    @Injected private var bluetoothManager: BluetoothConnectionObservable
    @Injected private var bluetootConnector: BluetoothConnectionHandler

    // Retry policy: device power-cycle reboot can exceed the 10 s connect timeout,
    // so a single shot fails immediately on a hard restart. Keep attempting until
    // the user-visible delegate stops asking us to reconnect (active session
    // cleared / user-driven disconnect) or we hit the cap. Cap is generous so
    // typical Mini Mini reboots (sub-30 s) complete inside the window.
    private static let connectAttemptTimeout: TimeInterval = 10
    private static let retryDelaySeconds: TimeInterval = 3
    private static let maxRetryAttempts: Int = 40 // ~10 + (39 × (10 + 3)) ≈ 8.5 minutes
    private let retryQueue = DispatchQueue(label: "ab.reconnection.controller")

    init() {
        bluetoothManager.addConnectionObserver(self)
    }

    deinit {
        bluetoothManager.removeConnectionObserver(self)
    }

    func didDisconnect(device: any BluetoothDevice) {
        guard delegate?.shouldReconnect(to: device) ?? false else { return }
        attemptReconnect(device: device, attempt: 1)
    }

    private func attemptReconnect(device: any BluetoothDevice, attempt: Int) {
        // Re-check on every retry: user may have stopped the session mid-loop.
        guard delegate?.shouldReconnect(to: device) ?? false else {
            Log.info("[RECONNECT] Aborted (no longer needed) attempt=\(attempt)")
            return
        }
        Log.info("[RECONNECT] Attempt #\(attempt) for \(device.uuid)")

        do {
            try bluetootConnector.connect(to: device, timeout: Self.connectAttemptTimeout) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    Log.info("[RECONNECT] Connected to peripheral (attempt #\(attempt)): \(device)")
                    do {
                        try self.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success:
                                Log.info("[RECONNECT] Discovered characteristics for: \(device)")
                                self.completeReconnection(for: device)
                            case .failure(let error):
                                Log.error("[RECONNECT] discoverCharacteristics failed (attempt #\(attempt)): \(error). Scheduling retry.")
                                self.scheduleRetry(device: device, attempt: attempt)
                            }
                        }
                    } catch {
                        Log.error("[RECONNECT] discoverCharacteristics threw (attempt #\(attempt)): \(error). Scheduling retry.")
                        self.scheduleRetry(device: device, attempt: attempt)
                    }
                case .failure(let error):
                    Log.warning("[RECONNECT] connect failed (attempt #\(attempt)): \(error). Scheduling retry.")
                    self.scheduleRetry(device: device, attempt: attempt)
                }
            }
        } catch {
            Log.error("[RECONNECT] connect threw (attempt #\(attempt)): \(error). Scheduling retry.")
            scheduleRetry(device: device, attempt: attempt)
        }
    }

    private func scheduleRetry(device: any BluetoothDevice, attempt: Int) {
        guard attempt < Self.maxRetryAttempts else {
            Log.error("[RECONNECT] Exhausted \(Self.maxRetryAttempts) attempts for \(device.uuid). Giving up.")
            delegate?.didFailToReconnect(to: device)
            return
        }
        retryQueue.asyncAfter(deadline: .now() + Self.retryDelaySeconds) { [weak self] in
            self?.attemptReconnect(device: device, attempt: attempt + 1)
        }
    }

    private func completeReconnection(for device: any BluetoothDevice) {
        completeReconnection(for: device, attempt: 1)
    }

    private func completeReconnection(for device: any BluetoothDevice, attempt: Int) {
        switch device.firmwareVersion {
        case .v1:
            self.delegate?.didReconnect(to: device)
        case .v2:
            // V2 path defers any post-reconnect action until the first Status notification arrives
            // so callers can read the device state before issuing commands. The configurator
            // is cached across disconnect — wipe stale subscriptions / status before re-subscribing.
            let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
            configurator.prepareForReconnect()
            configurator.subscribeAndAwaitStatus { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let status):
                    Log.info("[RECONNECT] V2 ready. Status=\(status)")
                    self.delegate?.didReconnect(to: device)
                case .failure(let error):
                    Log.error("[RECONNECT] V2 status failed (attempt #\(attempt)): \(error). Scheduling retry.")
                    self.scheduleRetry(device: device, attempt: attempt)
                }
            }
        }
    }
}
