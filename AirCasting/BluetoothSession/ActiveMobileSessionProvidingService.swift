import Resolver

protocol ActiveMobileSessionProvidingService {
    var activeSession: MobileSession? { get }
    func setActiveSession(session: Session, device: NewBluetoothManager.BluetoothDevice)
    func clearActiveSession()
}

// TODO: Remove MobilePeripheralSessionManager after refactor
final class ActiveMobileSessionProvidingServiceBridge: ActiveMobileSessionProvidingService {
    @Injected private var mobileSessionManager: MobilePeripheralSessionManager
    
    var activeSession: MobileSession? {
        mobileSessionManager.activeMobileSession
    }
    
    func setActiveSession(session: Session, device: NewBluetoothManager.BluetoothDevice) {
        mobileSessionManager.activeMobileSession = MobileSession(device: device, session: session)
    }
    
    func clearActiveSession() {
        mobileSessionManager.activeMobileSession = nil
    }
}
