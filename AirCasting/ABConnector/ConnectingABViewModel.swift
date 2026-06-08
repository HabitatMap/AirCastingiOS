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
    /// Phase 6: surface the Sync/Discard/Cancel dialog when a V2 device is in
    /// `HasSavedSession` and the user is starting a new session.
    @Published var pendingSyncDialog: SyncBeforeNewV2SessionViewModel? = nil

    private let device: any BluetoothDevice
    private let sessionContext: CreateSessionContext
    
    required init(sessionContext: CreateSessionContext,
                  device: any BluetoothDevice) {
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
                                self.proceedAfterConfigureOrShowSyncDialog()
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
    
    /// Phase 6: after the V2 configurator has subscribed and decoded the
    /// first Status notification, branch on `HasSavedSession` (with stored
    /// measurements) and surface the Sync / Discard / Cancel dialog before
    /// navigating onward to the rest of the session-creation flow.
    private func proceedAfterConfigureOrShowSyncDialog() {
        guard device.firmwareVersion == .v2 else {
            isDeviceConnected = true
            return
        }
        let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
        guard case .hasSavedSession(_, _, let hasMeasurements, _) = configurator.lastStatus,
              hasMeasurements else {
            isDeviceConnected = true
            return
        }
        pendingSyncDialog = SyncBeforeNewV2SessionViewModel(
            configurator: configurator,
            onResolved: { [weak self] outcome in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.pendingSyncDialog = nil
                    switch outcome {
                    case .proceedWithNewSession:
                        self.isDeviceConnected = true
                    case .cancel:
                        self.shouldDismiss = true
                    }
                }
            }
        )
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
