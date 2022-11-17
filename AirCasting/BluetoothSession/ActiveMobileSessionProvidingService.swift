import Resolver

protocol ActiveMobileSessionProvidingService {
    var activeSession: MobileSession? { get }
    func clearActiveSession()
}

// TODO: Remove MobilePeripheralSessionManager after refactor
final class ActiveMobileSessionProvidingServiceBridge: ActiveMobileSessionProvidingService {
    @Injected private var mobileSessionManager: MobilePeripheralSessionManager
    
    var activeSession: MobileSession? {
        mobileSessionManager.activeMobileSession
    }
    
    func clearActiveSession() {
        mobileSessionManager.activeMobileSession = nil
    }
}
