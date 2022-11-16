import Resolver

protocol SessionDisconnectController {
    func disconnectSession()
}

final class BluetoothSessionDisconnectController: SessionDisconnectController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    private let device: NewBluetoothManager.BluetoothDevice
    
    init(device: NewBluetoothManager.BluetoothDevice) {
        self.device = device
    }
    
    func disconnectSession() {
        guard let activeSession = activeSessionProvider.activeSession,
              activeSession.device == device
        else {
            Log.warning("Tried to disconnect session for peripheral which is not associated with an active session")
            return
        }
        let sessionUUID = activeSession.session.uuid
        Log.info("Changing session status to disconnected for: \(sessionUUID)")
        
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.DISCONNECTED, for: sessionUUID)
            } catch {
                Log.error("Unable to change session status to disconnected because of an error: \(error)")
            }
        }
    }
}

final class DefaultDisconnectController: SessionDisconnectController {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    
    func disconnectSession() {
        guard let sessionUUID = activeSessionProvider.activeSession?.session.uuid else {
            Log.warning("Tried to disconnect when no active session")
            return
        }
        Log.info("Changing session status to disconnected for: \(sessionUUID)")
        
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.DISCONNECTED, for: sessionUUID)
            } catch {
                Log.error("Unable to change session status to disconnected because of an error: \(error)")
            }
        }
    }
}
