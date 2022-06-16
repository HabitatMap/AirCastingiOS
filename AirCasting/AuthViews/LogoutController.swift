// Created by Lunar on 26/04/2022.
//

import Foundation
import Resolver
import Combine

protocol LogoutController {
    func logout(onEnd: @escaping () -> Void) throws
    func signOutButtonTapped()
    var alert: AlertInfo? { get set }
}

final class DefaultLogoutController: LogoutController {
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var removeDataController: RemoveDataController
    @Injected private var networkChecker: NetworkChecker
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @InjectedObject private var userState: UserState
    @Published var alert: AlertInfo?

    private let responseHandler = AuthorizationHTTPResponseHandler()

    func logout(onEnd: @escaping () -> Void) throws {
        if sessionSynchronizer.syncInProgress.value {
            var subscription: AnyCancellable?
            subscription = sessionSynchronizer.syncInProgress.receive(on: DispatchQueue.main).sink { [weak self] value in
                guard value == false else { return }
                self?.removeDataController.removeData()
                subscription?.cancel()
                onEnd()
            }
            return
        }
        // For logout we only care about uploading sessions before we remove everything
        sessionSynchronizer.triggerSynchronization(options: [.upload], completion: {
            DispatchQueue.main.async { self.removeDataController.removeData(); onEnd() }
        })
    }
    
    func signOutButtonTapped() {
        guard networkChecker.connectionAvailable else {
            showAlert(InAppAlerts.unableToLogOutAlert())
            return
        }
        
        measurementStreamStorage.accessStorage { storage in
            do {
                let result = try storage.anyLocationlessSessionsPresent()
                switch result {
                case true:
                    self.showAlert(InAppAlerts.logoutWarningAlert {
                        self.logoutUser()
                    })
                case false: self.logoutUser()
                }
            } catch {
                Log.error("Error when informing the user about loosing locationless sessions")
            }
        }
    }
    
    private func logoutUser() {
        userState.currentState = .loggingOut
        do {
            try logout {
                self.userState.currentState = .idle
            }
        } catch {
            userState.currentState = .idle
            assertionFailure("Failed to deauthorize \(error)")
        }
    }
    
    private func showAlert(_ alert: AlertInfo) {
        DispatchQueue.main.async {
            self.alert = alert
        }
    }
}
