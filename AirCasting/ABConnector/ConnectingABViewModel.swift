// Created by Lunar on 21/07/2021.
//

import Combine
import Foundation
import Resolver

// [RESOLVER] Move this VM init to View when all dependencies resolved
class AirbeamConnectionViewModel: ObservableObject {
    @Injected private var airBeamConnectionController: AirBeamConnectionController
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    @Injected private var bluetoothConnectionProtector: ConnectionProtectable
    
    @Published var isDeviceConnected: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var alert: AlertInfo? = nil
    
    private let device: NewBluetoothManager.BluetoothDevice
    private let sessionContext: CreateSessionContext
    
    required init(sessionContext: CreateSessionContext,
                  device: NewBluetoothManager.BluetoothDevice) {
        self.device = device
        self.sessionContext = sessionContext
    }
    
    func connectToAirBeam() {
        self.bluetoothConnectionProtector.isAirBeamAvailableForNewConnection(peripheraUUID: device.uuid) { result in
            switch result {
            case .success(_):
                self.airBeamConnectionController.connectToAirBeam(device: self.device) { result in
                    guard result == .success else {
                        DispatchQueue.main.async {
                            self.getAlert(result)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        self.isDeviceConnected = true
                    }
                    self.configureAB()
                }
            case .failure(let error):
                Log.info("Cannot create new mobile session while other is ongoing \(error.localizedDescription)")
                self.getAlert(.deviceBusy); return
            }
        }
    }
    
    private func configureAB() {
        if let sessionUUID = self.sessionContext.sessionUUID {
            // [Resolver] NOTE: Do we want configurator to be injected?
            let configurator = AirBeam3Configurator(device: self.device)
            do {
                try configurator.configureFixed(uuid: sessionUUID)
            } catch {
                Log.info("Couldn't configure AB to fixed session with uuid: \(sessionUUID)")
            }
        }
    }
    
    private func getAlert(_ result: AirBeamServicesConnectionResult) {
        switch result {
        case .timeout:
            self.alert = InAppAlerts.connectionTimeoutAlert {
                self.shouldDismiss = true
            }
        case .deviceBusy:
            self.alert = InAppAlerts.bluetoothSessionAlreadyRecordingAlert {
                self.shouldDismiss = true
            }
        case .success:
            break
        case .incompatibleDevice:
            self.alert = InAppAlerts.incompatibleDevice {
                self.shouldDismiss = true
            }
        }
    }
}
