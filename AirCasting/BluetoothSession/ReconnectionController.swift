// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver

protocol ReconnectionControllerDelegate: AnyObject {
    func shouldReconnect(to device: any BluetoothDevice) -> Bool
    /// Called once when a reconnect chain starts (after a real disconnect). Use it to
    /// surface "disconnected / reconnecting…" UI while the loop retries.
    func didStartReconnecting(to device: any BluetoothDevice)
    func didReconnect(to device: any BluetoothDevice)
}

extension ReconnectionControllerDelegate {
    func didStartReconnecting(to device: any BluetoothDevice) { }
}

protocol ReconnectionController {
    var delegate: ReconnectionControllerDelegate? { get set }
    /// Cancel an in-flight automatic reconnect chain for the given device UUID.
    /// Used when the user taps the manual Reconnect button so the manual attempt
    /// doesn't race the retry loop.
    func cancelReconnect(deviceUUID: String)
    /// Skip the current retry sleep and try the next reconnect attempt immediately.
    /// If no chain is active, start one. Returns true if a chain is now active.
    @discardableResult
    func kickReconnectNow(for device: any BluetoothDevice) -> Bool
}

class DefaultReconnectionController: ReconnectionController, BluetoothConnectionObserver {
    weak var delegate: ReconnectionControllerDelegate?
    @Injected private var bluetoothManager: BluetoothConnectionObservable
    @Injected private var bluetootConnector: BluetoothConnectionHandler

    // Retry policy: device power-cycle reboot can exceed the 10 s connect timeout,
    // so a single shot fails immediately on a hard restart. Keep attempting
    // indefinitely; the chain self-terminates once `shouldReconnect` returns
    // false (active session cleared / user-driven stop) or `cancelReconnect`
    // is called. Matches Android (neverending attempts) so a user who leaves
    // their AirBeam off for hours can still resume the same mobile session
    // when it powers back on instead of being silently moved to standalone.
    private static let connectAttemptTimeout: TimeInterval = 10
    private static let retryDelaySeconds: TimeInterval = 3
    private let retryQueue = DispatchQueue(label: "ab.reconnection.controller")

    // CoreBluetooth emits two disconnect notifications when a connect attempt times out
    // (the real power-cycle disconnect, plus a cleanup disconnect when our connect call
    // is cancelled). Without dedup each disconnect spawns a fresh reconnect chain and
    // they thrash `deviceBusy` against each other.
    private let activeReconnectsLock = NSLock()
    private var activeReconnects: Set<String> = []

    init() {
        bluetoothManager.addConnectionObserver(self)
    }

    deinit {
        bluetoothManager.removeConnectionObserver(self)
    }

    func didDisconnect(device: any BluetoothDevice) {
        guard delegate?.shouldReconnect(to: device) ?? false else { return }
        activeReconnectsLock.lock()
        let alreadyInFlight = activeReconnects.contains(device.uuid)
        if !alreadyInFlight {
            activeReconnects.insert(device.uuid)
        }
        activeReconnectsLock.unlock()
        guard !alreadyInFlight else {
            Log.info("[RECONNECT] Already in flight for \(device.uuid), skipping new chain.")
            return
        }
        delegate?.didStartReconnecting(to: device)
        attemptReconnect(device: device, attempt: 1)
    }

    private func clearInFlight(_ uuid: String) {
        activeReconnectsLock.lock()
        activeReconnects.remove(uuid)
        activeReconnectsLock.unlock()
    }

    func cancelReconnect(deviceUUID: String) {
        // Pulling the UUID out of activeReconnects causes the next scheduled retry
        // to see `shouldReconnect` still true but the chain considers itself done;
        // we also clear the flag explicitly so a follow-up didDisconnect can start a
        // fresh chain. In-flight `connect`/`discoverCharacteristics` callbacks will
        // run to completion and find their UUID no longer tracked.
        Log.info("[RECONNECT] Cancelling chain for \(deviceUUID) (manual reconnect requested)")
        clearInFlight(deviceUUID)
    }

    @discardableResult
    func kickReconnectNow(for device: any BluetoothDevice) -> Bool {
        // Manual Reconnect tap: ensure a chain is active and try the next attempt
        // immediately instead of waiting out the 3 s retry sleep. If no chain is
        // active (e.g., manual tap from post-exhaustion standalone), start one.
        activeReconnectsLock.lock()
        let wasInFlight = activeReconnects.contains(device.uuid)
        if !wasInFlight {
            activeReconnects.insert(device.uuid)
        }
        activeReconnectsLock.unlock()
        Log.info("[RECONNECT] Manual kick for \(device.uuid) (wasInFlight=\(wasInFlight))")
        if !wasInFlight {
            delegate?.didStartReconnecting(to: device)
        }
        retryQueue.async { [weak self] in
            self?.attemptReconnect(device: device, attempt: 1)
        }
        return true
    }

    private func attemptReconnect(device: any BluetoothDevice, attempt: Int) {
        // Re-check on every retry: user may have stopped the session mid-loop,
        // or fired a manual Reconnect that cancelled the auto chain.
        activeReconnectsLock.lock()
        let stillActive = activeReconnects.contains(device.uuid)
        activeReconnectsLock.unlock()
        guard stillActive else {
            Log.info("[RECONNECT] Aborted (chain cancelled) attempt=\(attempt) for \(device.uuid)")
            return
        }
        guard delegate?.shouldReconnect(to: device) ?? false else {
            Log.info("[RECONNECT] Aborted (no longer needed) attempt=\(attempt)")
            clearInFlight(device.uuid)
            return
        }
        Log.info("[RECONNECT] Attempt #\(attempt) for \(device.uuid)")

        do {
            try bluetootConnector.connect(to: device, timeout: Self.connectAttemptTimeout) { [weak self] result in
                guard let self = self else { return }
                guard self.isStillActive(device.uuid) else {
                    Log.info("[RECONNECT] connect callback fired after cancel; dropping (attempt #\(attempt))")
                    return
                }
                switch result {
                case .success:
                    Log.info("[RECONNECT] Connected to peripheral (attempt #\(attempt)): \(device)")
                    do {
                        try self.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { [weak self] result in
                            guard let self = self else { return }
                            guard self.isStillActive(device.uuid) else {
                                Log.info("[RECONNECT] discoverCharacteristics callback fired after cancel; dropping")
                                return
                            }
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

    private func isStillActive(_ uuid: String) -> Bool {
        activeReconnectsLock.lock(); defer { activeReconnectsLock.unlock() }
        return activeReconnects.contains(uuid)
    }

    private func scheduleRetry(device: any BluetoothDevice, attempt: Int) {
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
            guard finalizeReconnectIfStillNeeded(device: device) else { return }
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
                    guard self.finalizeReconnectIfStillNeeded(device: device) else { return }
                    self.delegate?.didReconnect(to: device)
                case .failure(let error):
                    Log.error("[RECONNECT] V2 status failed (attempt #\(attempt)): \(error). Scheduling retry.")
                    self.scheduleRetry(device: device, attempt: attempt)
                }
            }
        }
    }

    /// Final gate before invoking `didReconnect`. The connect / discover /
    /// V2-status callbacks can fire AFTER `cancelReconnect` (e.g. SD sync
    /// wizard suppression kicked in mid-callback): without this re-check we
    /// would call `didReconnect` -> `resumeRecording` and silently race the
    /// wizard's own BLE traffic. Returns true if the caller should proceed.
    @discardableResult
    private func finalizeReconnectIfStillNeeded(device: any BluetoothDevice) -> Bool {
        guard isStillActive(device.uuid) else {
            Log.info("[RECONNECT] Finalize aborted (chain cancelled) for \(device.uuid)")
            return false
        }
        guard delegate?.shouldReconnect(to: device) ?? false else {
            Log.info("[RECONNECT] Finalize aborted (no longer needed) for \(device.uuid)")
            clearInFlight(device.uuid)
            return false
        }
        clearInFlight(device.uuid)
        return true
    }
}
