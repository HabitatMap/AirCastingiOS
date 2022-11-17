import Resolver

protocol ActiveMobileSessionProvidingService {
    var activeSession: MobileSession? { get }
    func setActiveSession(session: Session, device: NewBluetoothManager.BluetoothDevice)
    func clearActiveSession()
}

final class DefaultActiveMobileSessionProvidingService: ActiveMobileSessionProvidingService {
    private(set) var activeSession: MobileSession?
    
    func setActiveSession(session: Session, device: NewBluetoothManager.BluetoothDevice) {
        activeSession = MobileSession(device: device, session: session)
    }
    
    func clearActiveSession() {
        activeSession = nil
    }
}
