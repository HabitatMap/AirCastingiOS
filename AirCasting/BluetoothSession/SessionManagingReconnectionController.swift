import Resolver

class SessionManagingReconnectionController: ReconnectionControllerDelegate {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var reconnectionController: ReconnectionController
    private let standaloneController: StandaloneModeController = Resolver.resolve(StandaloneModeController.self, args: StandaloneOrigin.device)
    @Injected private var bluetoothSessionController: BluetoothSessionRecordingController
    
    init() {
        reconnectionController.delegate = self
    }
    
    func shouldReconnect(to device: any BluetoothDevice) -> Bool {
        activeSessionProvider.activeSession?.device.uuid == device.uuid
    }
    
    func didReconnect(to device: any BluetoothDevice) {
        bluetoothSessionController.resumeRecording(device: device) { result in
            switch result {
            case .success: Log.info("Reconnection successful")
            case .failure(let error): Log.error("Reconnection failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    func didFailToReconnect(to device: any BluetoothDevice) {
        guard activeSessionProvider.activeSession?.device.uuid == device.uuid else { return }
        standaloneController.moveActiveSessionToStandaloneMode()
    }
}
