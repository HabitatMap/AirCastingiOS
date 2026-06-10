import Resolver
import Foundation

class SessionManagingReconnectionController: ReconnectionControllerDelegate {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var reconnectionController: ReconnectionController
    @Injected private var measurementsSaver: MeasurementsSavingService
    @Injected private var persistence: MobileSessionRecordingStorage
    private let standaloneController: StandaloneModeController = Resolver.resolve(StandaloneModeController.self, args: StandaloneOrigin.device)
    @Injected private var bluetoothSessionController: BluetoothSessionRecordingController

    // Device UUIDs for which automatic reconnect must NOT fire. Used by the SD
    // sync flow: the user is mid-flow on a device that also has an active
    // mobile recording session, so without suppression `shouldReconnect`
    // returns true and the auto-reconnect chain races the SD sync's own
    // explicit connect/disconnect calls — yielding stale CBCharacteristic
    // pointers and CoreBluetooth-side malloc crashes during the clear-SD
    // step.
    private let suppressedUUIDsLock = NSLock()
    private var suppressedUUIDs: Set<String> = []

    init() {
        reconnectionController.delegate = self
    }

    /// Suppress automatic reconnect for `deviceUUID` until `releaseReconnect`
    /// is called. Also cancels any in-flight reconnect chain so a retry
    /// already scheduled stops firing.
    func suppressReconnect(deviceUUID: String) {
        suppressedUUIDsLock.lock()
        suppressedUUIDs.insert(deviceUUID)
        suppressedUUIDsLock.unlock()
        reconnectionController.cancelReconnect(deviceUUID: deviceUUID)
    }

    /// Re-enable automatic reconnect for `deviceUUID`. Pair with a prior
    /// `suppressReconnect` call from the same flow.
    func releaseReconnect(deviceUUID: String) {
        suppressedUUIDsLock.lock()
        suppressedUUIDs.remove(deviceUUID)
        suppressedUUIDsLock.unlock()
    }

    func shouldReconnect(to device: any BluetoothDevice) -> Bool {
        suppressedUUIDsLock.lock()
        let suppressed = suppressedUUIDs.contains(device.uuid)
        suppressedUUIDsLock.unlock()
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
