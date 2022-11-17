import Resolver

protocol StandaloneController {
    func moveActiveSessionToStandaloneMode()
}

final class DefaultStandaloneContoller: StandaloneController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var locationTracker: LocationTracker
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    
    func moveActiveSessionToStandaloneMode() {
        guard let session = activeSessionProvider.activeSession?.session else { return }
        
        guard let sessionUUID = activeSessionProvider.activeSession?.session.uuid else {
            Log.warning("Tried to disconnect when no active session")
            return
        }
        Log.info("Changing session status to disconnected for: \(sessionUUID)")
        
        performDatabaseChange(for: sessionUUID)
        
        if !session.locationless {
            locationTracker.stop()
        }
        
        activeSessionProvider.clearActiveSession()
    }
    
    private func performDatabaseChange(for sessionUUID: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.DISCONNECTED, for: sessionUUID)
            } catch {
                Log.error("Unable to change session status to disconnected because of an error: \(error)")
            }
        }
    }
}

final class UserInitiatedStandaloneController: StandaloneController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    private let standaloneController: StandaloneController = Resolver.resolve(StandaloneController.self, args: StandaloneOrigin.device)
    @Injected private var bluetootConnector: BluetoothConnectionHandler
    
    func moveActiveSessionToStandaloneMode() {
        guard let device = activeSessionProvider.activeSession?.device else { return }
        bluetootConnector.disconnect(from: device)
        standaloneController.moveActiveSessionToStandaloneMode()
    }
}
