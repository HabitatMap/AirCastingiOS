// Created by Lunar on 28/10/2022.
//

import Foundation
import Resolver
import Combine

class ReconnectSessionCardViewModel: ObservableObject {
    let session: SessionEntity
    var cancellable: AnyCancellable?
    @Published var alert: AlertInfo?
    @Published var isSpinnerOn = false
    @Injected private var bm: BluetoothManager
    
    init(session: SessionEntity) {
        self.session = session
        cancellable = bm.$isReconnectionOn.sink { value in
            self.isSpinnerOn = value
        }
    }
    
    deinit {
        self.cancellable = nil
    }
    
    func onRecconectTap() {
        guard let databaseUUID = session.bluetoothConnection?.peripheralUUID else { Log.error("Trying to ger uuid but it is not saved."); showReconnectionAlert(); return }
        guard let matchingUUID = bm.devices.first(where: { $0.identifier.description == databaseUUID }) else { Log.error("no matching uuid"); showReconnectionAlert(); return }
        bm.connectWithTimeout(using: matchingUUID)
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
            Log.info("error when stpoing session - \(error)")
        }
    }
    
    private func showReconnectionAlert() {
        alert = InAppAlerts.cannotReconnectSession(sessionName: session.name)
    }
}
