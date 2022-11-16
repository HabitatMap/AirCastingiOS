import Resolver

// TODO: Maybe rename?
class SessionReconnectionController: ReconnectionControllerDelegate {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var reconnectionController: ReconnectionController
    private let standaloneController: StandaloneController = Resolver.resolve(StandaloneController.self, args: StandaloneOrigin.device)
    @Injected private var bluetoothSessionController: BluetoothSessionController
    
    init() {
        reconnectionController.delegate = self
    }
    
    func shouldReconnect(to device: NewBluetoothManager.BluetoothDevice) -> Bool {
        activeSessionProvider.activeSession?.device == device
    }
    
    func didDisconnect(device: NewBluetoothManager.BluetoothDevice) {
        let controller = Resolver.resolve(SessionDisconnectController.self, args: device)
        controller.disconnectSession()
    }
    
    func didReconnect(to device: NewBluetoothManager.BluetoothDevice) {
        bluetoothSessionController.resumeRecording(device: device) { result in
            switch result {
            case .success: Log.info("Reconnection successful")
            case .failure(let error): Log.error("Reconnection failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    func didFailToReconnect(to device: NewBluetoothManager.BluetoothDevice) {
        guard activeSessionProvider.activeSession?.device == device else { return }
        standaloneController.moveActiveSessionToStandaloneMode()
    }
}
