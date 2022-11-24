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
    @Published var isSpinnerOn = false
    private var reconnectionController = UserTriggeredReconnectionController()
    
    init(session: SessionEntity) {
        self.session = session
    }
    
    func onRecconectTap() {
        guard let peripheralUUID = session.bluetoothConnection?.peripheralUUID else { Log.error("Trying to get uuid but it is not saved."); showReconnectionAlert(); return }
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
    
    private func showReconnectionAlert() {
        alert = InAppAlerts.cannotReconnectSession(sessionName: session.name)
    }
    
    private func connect(with uuid: String) {
        isSpinnerOn = true
        reconnectionController.reconnectWithPeripheral(deviceUUID: uuid) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let device):
                let session = self.session
                self.activeSessionProvider.setActiveSession(session: Session(uuid: session.uuid, type: session.type, name: session.name, deviceType: session.deviceType, location: session.location, startTime: session.startTime), device: device)
                self.sessionRecorder.resumeRecording(device: device) { result in
                    switch result {
                    case .success():
                        Log.info("## Success")
                        DispatchQueue.main.async {
                            self.isSpinnerOn = false
                        }
                    case .failure(let error):
                        Log.info("## ERROR: \(error)")
                        DispatchQueue.main.async {
                            self.isSpinnerOn = false
                        }
                    }
                }
            case .failure(let error):
                Log.info("## ERROR: \(error)")
                DispatchQueue.main.async {
                    self.isSpinnerOn = false
                }
            }
        }
    }
}
