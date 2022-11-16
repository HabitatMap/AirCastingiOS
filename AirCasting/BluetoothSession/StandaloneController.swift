import Resolver

protocol StandaloneController {
    func moveActiveSessionToStandaloneMode()
}

final class DefaultStandaloneContoller: StandaloneController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var locationTracker: LocationTracker
    @Injected private var sessionStorage: SessionStorage
    @Injected private var sessionDisconnectController: SessionDisconnectController
    
    func moveActiveSessionToStandaloneMode() {
        guard let session = activeSessionProvider.activeSession?.session else { return }
        
        sessionDisconnectController.disconnectSession()
        
        if !session.locationless {
            locationTracker.stop()
        }
        
        activeSessionProvider.clearActiveSession()
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
