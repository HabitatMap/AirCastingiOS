// Created by Lunar on 16/06/2022.
//

import Foundation
import Resolver

final class SettingsMyAccountViewModel: ObservableObject {
    @Injected private var networkChecker: NetworkChecker
    @Injected private var sessionEntityStore: SessionEntityStore
    @Injected private var logoutController: LogoutController
    @Injected private var deleteController: DeleteAccountController
    @InjectedObject private var userState: UserState
    @Published var alert: AlertInfo?
    
    func signOutButtonTapped() {
        guard networkChecker.connectionAvailable else {
            showAlert(InAppAlerts.noInternetConnectionSignOutAlert())
            return
        }
        
        do {
            let result = try sessionEntityStore.anyLocationlessSessionsPresent()
            switch result {
            case true:
                self.showAlert(InAppAlerts.logoutWarningAlert {
                    self.logoutUser()
                })
            case false: self.logoutUser()
            }
        } catch {
            Log.error("Error when informing the user about loosing locationless sessions")
            self.showAlert(InAppAlerts.failedFetchingLocationlessSessionsAlert())
        }
    }
    
    func deleteButtonTapped() {
        showAlert(InAppAlerts.firstConfirmationDeletingAccountAlert {
            self.showAlert(InAppAlerts.secondConfirmationDeletingAccountAlert {
                guard self.networkChecker.connectionAvailable else {
                    self.showAlert(InAppAlerts.unableToConnectBeforeDeletingAccount())
                    return
                }
                self.changeUserState(to: .deletingAccount)
                self.deleteController.deleteAccount { result in
                    self.changeUserState(to: .idle)
                    switch result {
                    case .success(_): break
                    case .failure(let error):
                        self.showAlert(InAppAlerts.failedDeletingAccount())
                        Log.error("Failed to delete account: \(error)")
                    }
                }
            })
        })
    }
    
    private func logoutUser() {
        changeUserState(to: .loggingOut)
        do {
            try logoutController.logout {
                self.changeUserState(to: .idle)
            }
        } catch {
            changeUserState(to: .idle)
            assertionFailure("Failed to deauthorize \(error)")
        }
    }
    
    private func changeUserState(to userState: UserState.State) {
        DispatchQueue.main.async {
            self.userState.currentState = userState
        }
    }
    
    private func showAlert(_ alert: AlertInfo) {
        DispatchQueue.main.async {
            self.alert = alert
        }
    }
}
