import Resolver
import Foundation

protocol StandaloneModeController {
    func moveActiveSessionToStandaloneMode()
}

final class DefaultStandaloneModeContoller: StandaloneModeController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var sessionRecordingController: BluetoothSessionRecordingController

    func moveActiveSessionToStandaloneMode() {
        guard let sessionUUID = activeSessionProvider.activeSession?.session.uuid else {
            Log.warning("Tried to disconnect when no active session")
            return
        }

        sessionRecordingController.stopRecordingSession(with: sessionUUID, databaseChange: {
            Log.info("Changing session status to disconnected for: \(sessionUUID)")
            $0.updateSessionStatus(.DISCONNECTED, for: sessionUUID)
        })
    }
}

final class UserInitiatedStandaloneModeController: StandaloneModeController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    private let standaloneController: StandaloneModeController = Resolver.resolve(StandaloneModeController.self, args: StandaloneOrigin.device)
    @Injected private var bluetoothConnector: BluetoothConnectionHandler

    func moveActiveSessionToStandaloneMode() {
        guard let device = activeSessionProvider.activeSession?.device else { return }
        try? bluetoothConnector.disconnect(from: device)
        standaloneController.moveActiveSessionToStandaloneMode()
    }
}
