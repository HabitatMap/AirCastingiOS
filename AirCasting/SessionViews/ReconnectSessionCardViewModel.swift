// Created by Lunar on 28/10/2022.
//

import Foundation
import Resolver
import Combine

class ReconnectSessionCardViewModel: ObservableObject {
    @Injected private var reconnectionController: UserTriggeredReconnectionController
    @Published var alert: AlertInfo?
    @Published var buttonLabel = Strings.ReconnectSessionCardView.reconnectLabel
    @Published var connectingState: ConnectingState = .idle {
        didSet {
            switch connectingState {
            case .idle:
                buttonLabel = Strings.ReconnectSessionCardView.reconnectLabel
            case .connecting:
                buttonLabel = Strings.ReconnectSessionCardView.connectingLabel
            }
        }
    }
    let session: SessionEntity

    enum ConnectingState {
        case idle
        case connecting
    }

    /// Tap → kicks the auto-retry chain. The card unmounts when status flips
    /// DISCONNECTED→RECORDING. If that flip doesn't happen inside this window
    /// (auto chain still retrying / device not back yet) revert to idle so the
    /// user can tap again.
    private static let connectingTimeoutSeconds: TimeInterval = 30
    
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
    
    private func showAlertFor(error: UserTriggeredReconnectionError) {
        switch error {
        case .anotherActiveSessionInProgress:
            alert = InAppAlerts.anotherSessionInProgress()
        case .deviceNotDiscovered:
            alert = InAppAlerts.failedToDiscoverDevice()
        case .failedToConnect:
            alert = InAppAlerts.failedToConnectWithDevice()
        }
    }
    
    private func connect(with uuid: String) {
        connectingState = .connecting
        // Revert to idle if the card hasn't unmounted (status flipped) within the
        // window. Keeps the button tappable when the auto chain is still chewing.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.connectingTimeoutSeconds) { [weak self] in
            guard let self = self, self.connectingState == .connecting else { return }
            self.connectingState = .idle
        }
        reconnectionController.reconnectWithPeripheral(deviceUUID: uuid, session: Session(uuid: session.uuid, type: session.type, name: session.name, deviceType: session.deviceType, location: session.location, startTime: session.startTime)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success():
                // No state change — stay in `.connecting` until the status flip
                // unmounts the card. Branch A returns success immediately after
                // kicking the auto chain, so `.connected` here would lie.
                break
            case .failure(let error):
                Log.info("Failed to reconnect: \(error)")
                DispatchQueue.main.async {
                    self.connectingState = .idle
                    self.showAlertFor(error: error)
                }
            }
        }
    }
}
