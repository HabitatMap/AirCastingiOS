import Resolver
import Foundation

class SessionManagingReconnectionController: ReconnectionControllerDelegate {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var reconnectionController: ReconnectionController
    @Injected private var measurementsSaver: MeasurementsSavingService
    @Injected private var persistence: MobileSessionRecordingStorage
    private let standaloneController: StandaloneModeController = Resolver.resolve(StandaloneModeController.self, args: StandaloneOrigin.device)
    @Injected private var bluetoothSessionController: BluetoothSessionRecordingController

    // Per-device suppression refcount. Each "owner" in the SD sync wizard
    // (the SDRestartABView screen, the sync view model, the clear-SD view
    // model) calls `suppressReconnect` on entry and `releaseReconnect` on
    // exit. Using a counter rather than a Set lets nested owners overlap
    // without one prematurely re-enabling auto-reconnect for the other. Auto
    // reconnect is blocked while count > 0.
    //
    // The SD sync flow exists because: with an active mobile recording
    // session on the same device, `shouldReconnect` returned true and the
    // reconnect chain ran behind the wizard — resuming recording after the
    // user-driven AB power cycle, racing the wizard's own connect/disconnect
    // calls, and yielding stale CBCharacteristic pointers that
    // CoreBluetooth double-freed during the clear-SD writeValue.
    private let suppressedCountsLock = NSLock()
    private var suppressedCounts: [String: Int] = [:]

    init() {
        reconnectionController.delegate = self
    }

    /// Increment the reconnect-suppression refcount for `deviceUUID`. While
    /// count > 0, `shouldReconnect` returns false for that device. Also
    /// cancels any in-flight reconnect chain so a retry already scheduled
    /// stops firing. Pair every call with a `releaseReconnect`.
    func suppressReconnect(deviceUUID: String) {
        suppressedCountsLock.lock()
        suppressedCounts[deviceUUID, default: 0] += 1
        suppressedCountsLock.unlock()
        reconnectionController.cancelReconnect(deviceUUID: deviceUUID)
    }

    /// Decrement the reconnect-suppression refcount for `deviceUUID`. Once
    /// the count returns to 0 the entry is removed and auto-reconnect can
    /// fire again on the next disconnect.
    func releaseReconnect(deviceUUID: String) {
        suppressedCountsLock.lock()
        let next = (suppressedCounts[deviceUUID] ?? 0) - 1
        if next <= 0 {
            suppressedCounts.removeValue(forKey: deviceUUID)
        } else {
            suppressedCounts[deviceUUID] = next
        }
        suppressedCountsLock.unlock()
    }

    func shouldReconnect(to device: any BluetoothDevice) -> Bool {
        suppressedCountsLock.lock()
        let suppressed = (suppressedCounts[device.uuid] ?? 0) > 0
        suppressedCountsLock.unlock()
        guard !suppressed else { return false }
        return activeSessionProvider.activeSession?.device.uuid == device.uuid
    }

    func didStartReconnecting(to device: any BluetoothDevice) {
        // Flip the active session to DISCONNECTED while we retry, so the session card
        // surfaces the "disconnected" affordance instead of pretending data is still
        // flowing. didReconnect flips it back to RECORDING via changeStatusToRecording.
        guard let sessionUUID = activeSessionProvider.activeSession?.session.uuid,
              activeSessionProvider.activeSession?.device.uuid == device.uuid else { return }
        persistence.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.DISCONNECTED, for: sessionUUID)
            } catch {
                Log.error("Failed to flip session to DISCONNECTED on reconnect start: \(error)")
            }
        }
    }

    func didReconnect(to device: any BluetoothDevice) {
        bluetoothSessionController.resumeRecording(device: device) { [weak self] result in
            switch result {
            case .success:
                Log.info("Reconnection successful")
                if let sessionUUID = self?.activeSessionProvider.activeSession?.session.uuid,
                   self?.activeSessionProvider.activeSession?.device.uuid == device.uuid {
                    self?.measurementsSaver.changeStatusToRecording(for: sessionUUID)
                }
            case .failure(let error):
                Log.error("Reconnection failed with error: \(error.localizedDescription)")
            }
        }
    }

    func didFailToReconnect(to device: any BluetoothDevice) {
        guard activeSessionProvider.activeSession?.device.uuid == device.uuid else { return }
        standaloneController.moveActiveSessionToStandaloneMode()
    }
}
