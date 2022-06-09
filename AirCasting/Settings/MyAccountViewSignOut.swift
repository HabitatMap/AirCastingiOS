// Created by Lunar on 18/06/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct MyAccountViewSignOut: View {
    @State private var alert: AlertInfo?
    @InjectedObject private var userAuthenticationSession: UserAuthenticationSession
    @InjectedObject private var userState: UserState
    @Injected private var networkChecker: NetworkChecker
    @Injected private var logoutController: LogoutController
    @Injected private var deleteController: DeleteAccountController
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                logInLabel
                signOutButton
                if featureFlagsViewModel.enabledFeatures.contains(.deleteAccount) {
                    deleteProfileButton
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Spacer()
            }
        }
        .navigationTitle(Strings.Commons.myAccount)
        .alert(item: $alert, content: { $0.makeAlert() })
    }
}

private extension MyAccountViewSignOut {
    var logInLabel: some View {
        Text(Strings.SignOutSettings.logged + "\(KeychainStorage(service:  Bundle.main.bundleIdentifier!).getUsername())")
            .foregroundColor(.aircastingGray)
            .font(Fonts.muliHeading2)
            .padding()
    }
    
    var signOutButton: some View {
        Button(action: {
            if true {
                alert = InAppAlerts.logoutWarningAlert {
                    logoutUser()
                }
            } else {
                logoutUser()
            }
        }) {
            Group {
                HStack {
                    Text(Strings.SignOutSettings.signOut)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(.horizontal)
            }
        }.buttonStyle(BlueButtonStyle())
        .padding()
    }
    
    var deleteProfileButton: some View {
        Button {
            alert = InAppAlerts.firstConfirmationDeletingAccountAlert {
                alert = InAppAlerts.secondConfirmationDeletingAccountAlert {
                    guard networkChecker.connectionAvailable else {
                        alert = InAppAlerts.unableToConnectBeforeDeletingAccount()
                        return
                    }
                    userState.currentState = .deletingAccount
                    deleteController.deleteAccount { result in
                        userState.currentState = .idle
                        switch result {
                        case .success(_): break
                        case .failure(let error):
                            alert = InAppAlerts.failedDeletingAccount()
                            assertionFailure("Failed to delete account: \(error)")
                        }
                    }
                }
            }
        } label: {
            Text(Strings.SignOutSettings.deleteAccount)
        }
        .foregroundColor(.red)
        .padding(.bottom, 20)
        .padding()
    }
    
    private func logoutUser() {
        guard networkChecker.connectionAvailable else {
            alert = InAppAlerts.unableToLogOutAlert()
            return
        }
        userState.currentState = .loggingOut
        do {
            try logoutController.logout {
                userState.currentState = .idle
            }
        } catch {
            userState.currentState = .idle
            assertionFailure("Failed to deauthorize \(error)")
        }
    }
    
}
