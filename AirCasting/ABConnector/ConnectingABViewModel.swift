// Created by Lunar on 21/07/2021.
//

import Combine
import Foundation
import Resolver

class AirbeamConnectionViewModel: ObservableObject {
    @Injected private var airBeamConnectionController: AirBeamConnectionController
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    @Injected private var bluetoothConnectionProtector: ConnectionProtectable
    private let configurator: AirBeamConfigurator
    
    @Published var isDeviceConnected: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var alert: AlertInfo? = nil
    
    private let device: NewBluetoothManager.BluetoothDevice
    private let sessionContext: CreateSessionContext
    
    required init(sessionContext: CreateSessionContext,
                  device: NewBluetoothManager.BluetoothDevice) {
        self.device = device
        self.sessionContext = sessionContext
        self.configurator = Resolver.resolve(AirBeamConfigurator.self, args: device)
    }
    
    struct NoSessionUUID: Error {}
    
    func connectToAirBeam() {
        self.bluetoothConnectionProtector.isAirBeamAvailableForNewConnection(peripheraUUID: device.uuid) { result in
            switch result {
            case .success(_):
                self.airBeamConnectionController.connectToAirBeam(device: self.device) { result in
                    guard result == AirBeamServicesConnectionResult.success else {
                        DispatchQueue.main.async {
                            self.getAlert(result)
                        }
                        return
                    }
                    self.configureAB { result in
                        switch result {
                        case .success():
                            DispatchQueue.main.async {
                                self.isDeviceConnected = true
                            }
                        case .failure(let error):
                            Log.error("Couldn't configure AB for fixed session: \(error)")
                            DispatchQueue.main.async {
                                self.alert = InAppAlerts.failedAirBeamConfiguration {
                                    self.shouldDismiss = true
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                Log.info("Cannot create new mobile session while other is ongoing \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.getAlert(.deviceBusy); return
                }
            }
        }
    }
    
    private func configureAB(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionUUID = self.sessionContext.sessionUUID else {
            completion(.failure(NoSessionUUID.init()))
            return
        }
        configurator
            .configureSession(uuid: sessionUUID, completion: completion)
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
        case .unknown(_):
            self.alert = InAppAlerts.genericErrorAlert {
                self.shouldDismiss = true
            }
        }
    }
}
