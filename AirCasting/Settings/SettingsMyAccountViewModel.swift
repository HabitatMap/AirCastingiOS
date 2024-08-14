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
    @InjectedObject private var userSettings: UserSettings
    @Published var alert: AlertInfo?
    @Published var showingAlert = false
    @Published var confirmationCode = ""
    
    func signOutButtonTapped() {
        guard networkChecker.connectionAvailable else {
            showAlert(InAppAlerts.noInternetConnectionSignOutAlert())
            return
        }
        
        guard !userSettings.syncOnlyThroughWifi || networkChecker.isUsingWifi else {
            showAlert(InAppAlerts.noWifiNetworkSyncAlert())
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
            self.changeUserState(to: .deletingAccount)
            self.deleteController.sendCode() { result in
                self.changeUserState(to: .idle)
                switch result {
                case .success(_):
                    DispatchQueue.main.async {
                        self.showingAlert.toggle()
                    }
                case .failure(let error):
                    self.showAlert(InAppAlerts.failedDeletingAccount())
                    Log.error("Failed to send the confirmation email, account not deleted: \(error)")
                }
            }
        })
    }
    
    func confirmCode() {
        guard self.networkChecker.connectionAvailable else {
            self.showAlert(InAppAlerts.unableToConnectBeforeDeletingAccount())
            return
        }
        
        self.changeUserState(to: .deletingAccount)
        
        self.deleteController.deleteAccount(confirmationCode: self.confirmationCode) { result in
            self.changeUserState(to: .idle)
            switch result {
            case .success(_): break
            case .failure(let error):
                self.showAlert(InAppAlerts.failedDeletingAccount())
                Log.error("Failed to delete account: \(error)")
            }
        }
        
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
