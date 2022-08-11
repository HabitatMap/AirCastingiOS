// Created by Lunar on 21/07/2021.
//

import Combine
import CoreBluetooth
import Resolver

// [RESOLVER] Move this VM init to View when all dependencies resolved
class AirbeamConnectionViewModel: ObservableObject {
    
    private enum AlertType {
        case timeOut
        case busyDevice
    }
    
    @Injected private var airBeamConnectionController: AirBeamConnectionController
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    @Injected private var bluetoothConnectionProtector: ConnectionProtectable
    
    @Published var isDeviceConnected: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var alert: AlertInfo? = nil
    
    private let peripheral: CBPeripheral
    private let sessionContext: CreateSessionContext
    
    required init(sessionContext: CreateSessionContext,
         peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.sessionContext = sessionContext
    }
    
    func connectToAirBeam() {
        self.bluetoothConnectionProtector.isAirBeamAvailableForNewConnection(peripheraUUID: peripheral.identifier.description) { result in
            switch result {
            case .success(_):
                self.airBeamConnectionController.connectToAirBeam(peripheral: self.peripheral) { success in
                    guard success else {
                        self.getAlert(.timeOut); return
                    }
                    self.isDeviceConnected = success
                    self.configureAB()
                }
            case .failure(let error):
                Log.info("Cannot create new mobile session while other is ongoing \(error.localizedDescription)")
                self.getAlert(.busyDevice); return
            }
        }
    }
    
    private func configureAB() {
        if let sessionUUID = self.sessionContext.sessionUUID {
            // [Resolver] NOTE: Do we want configurator to be injected?
            let configurator = AirBeam3Configurator(peripheral: self.peripheral)
            do {
                try configurator.configureFixed(uuid: sessionUUID)
            } catch {
                Log.info("Couldn't configure AB to fixed session with uuid: \(sessionUUID)")
            }
        }
    }
    
    private func getAlert(_ alert: AlertType) {
        switch alert {
        case .timeOut:
            self.alert = InAppAlerts.connectionTimeoutAlert {
                self.shouldDismiss = true
            }
        case .busyDevice:
            self.alert = InAppAlerts.bluetoothSessionAlreadyRecordingAlert {
                self.shouldDismiss = true
            }
        }
    }
}
