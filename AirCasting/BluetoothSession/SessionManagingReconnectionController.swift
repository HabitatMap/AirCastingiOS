import Resolver

class SessionManagingReconnectionController: ReconnectionControllerDelegate {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var reconnectionController: ReconnectionController
    @Injected private var measurementsSaver: MeasurementsSavingService
    @Injected private var persistence: MobileSessionRecordingStorage
    private let standaloneController: StandaloneModeController = Resolver.resolve(StandaloneModeController.self, args: StandaloneOrigin.device)
    @Injected private var bluetoothSessionController: BluetoothSessionRecordingController

    init() {
        reconnectionController.delegate = self
    }

    func shouldReconnect(to device: any BluetoothDevice) -> Bool {
        activeSessionProvider.activeSession?.device.uuid == device.uuid
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
