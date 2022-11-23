import Resolver
import Foundation

protocol StandaloneModeController {
    func moveActiveSessionToStandaloneMode()
}

final class DefaultStandaloneModeContoller: StandaloneModeController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var locationTracker: LocationTracker
    @Injected private var storage: MobileSessionStorage
    
    func moveActiveSessionToStandaloneMode() {
        guard let session = activeSessionProvider.activeSession?.session else { return }
        
        guard let sessionUUID = activeSessionProvider.activeSession?.session.uuid else {
            Log.warning("Tried to disconnect when no active session")
            return
        }
        Log.info("Changing session status to disconnected for: \(sessionUUID)")
        
        performDatabaseStatusUpdate(for: sessionUUID)
        
        if !session.locationless {
            locationTracker.stop()
        }
        
        activeSessionProvider.clearActiveSession()
    }
    
    private func performDatabaseStatusUpdate(for sessionUUID: SessionUUID) {
        storage.updateSessionStatus(.DISCONNECTED, for: sessionUUID)
    }
}

final class UserInitiatedStandaloneModeController: StandaloneModeController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    private let standaloneController: StandaloneModeController = Resolver.resolve(StandaloneModeController.self, args: StandaloneOrigin.device)
    @Injected private var bluetootConnector: BluetoothConnectionHandler
    
    func moveActiveSessionToStandaloneMode() {
        guard let device = activeSessionProvider.activeSession?.device else { return }
        bluetootConnector.disconnect(from: device)
        standaloneController.moveActiveSessionToStandaloneMode()
    }
}
