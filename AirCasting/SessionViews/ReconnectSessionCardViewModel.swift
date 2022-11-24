// Created by Lunar on 28/10/2022.
//

import Foundation
import Resolver
import Combine

class ReconnectSessionCardViewModel: ObservableObject {
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var sessionRecorder: BluetoothSessionRecordingController
    let session: SessionEntity
    @Published var alert: AlertInfo?
    @Published var connectingState: ConnectingState = .idle {
        didSet {
            switch connectingState {
            case .idle:
                buttonLabel = Strings.ReconnectSessionCardView.reconnectLabel
            case .connecting:
                buttonLabel = Strings.ReconnectSessionCardView.connectingLabel
            case .connected:
                buttonLabel = Strings.ReconnectSessionCardView.connectedLabel
            }
        }
    }
    @Published var buttonLabel = Strings.ReconnectSessionCardView.reconnectLabel
    
    private var reconnectionController = UserTriggeredReconnectionController()
    
    enum ConnectingState {
        case idle
        case connecting
        case connected
    }
    
    init(session: SessionEntity) {
        self.session = session
    }
    
    func onRecconectTap() {
        guard let peripheralUUID = session.bluetoothConnection?.peripheralUUID else { Log.error("Trying to get uuid but it is not saved."); showGenericAlert(); return }
        connect(with: peripheralUUID)
    }
    
    func onFinishDontSyncTapped(completion: @escaping () -> Void) {
        alert = InAppAlerts.finishSessionAlert(sessionName: session.name) {
            self.finishSessionAlertAction(completion: completion)
        }
    }
    
    private func finishSessionAlertAction(completion: () -> Void) {
        let sessionStopper = Resolver.resolve(SessionStoppable.self, args: session)
        do {
            try sessionStopper.stopSession()
            completion()
        } catch {
            Log.info("error when stopping session - \(error)")
            alert = InAppAlerts.failedFinishingSession()
        }
    }
    
    private func showGenericAlert() {
        alert = InAppAlerts.genericErrorAlert()
    }
    
    private func showAlertFor(error: UserTroggeredReconnectionError) {
        switch error {
        case .anotherActiveSessionInProgress:
            alert = InAppAlerts.anotherSessionInProgress()
        case .deviceNotDiscovered:
            alert = InAppAlerts.failedToDiscoverDevice()
        case .failedToConnect, .failedToDiscoverCharacteristics, .airbeamConfigurationFailure:
            alert = InAppAlerts.failedToConnectWithDevice()
        }
    }
    
    private func connect(with uuid: String) {
        connectingState = .connecting
        reconnectionController.reconnectWithPeripheral(deviceUUID: uuid) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let device):
                let session = self.session
                self.activeSessionProvider.setActiveSession(session: Session(uuid: session.uuid, type: session.type, name: session.name, deviceType: session.deviceType, location: session.location, startTime: session.startTime), device: device)
                self.sessionRecorder.resumeRecording(device: device) { result in
                    switch result {
                    case .success():
                        DispatchQueue.main.async {
                            self.connectingState = .connected
                        }
                    case .failure(let error):
                        Log.info("## ERROR: \(error)")
                        DispatchQueue.main.async {
                            self.connectingState = .idle
                            self.showAlertFor(error: .airbeamConfigurationFailure)
                        }
                    }
                }
            case .failure(let error):
                Log.info("## ERROR: \(error)")
                DispatchQueue.main.async {
                    self.connectingState = .idle
                    self.showAlertFor(error: error)
                }
            }
        }
    }
}
