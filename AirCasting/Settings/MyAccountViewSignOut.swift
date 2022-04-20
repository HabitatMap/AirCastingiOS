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
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                logInLabel
                signOutButton
                Spacer()
                HStack() {
                    Spacer()
                    deleteProfileButton
                    Spacer()
                }
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
            userState.currentState = .loggingOut
            guard networkChecker.connectionAvailable else {
                alert = InAppAlerts.unableToLogOutAlert()
                return
            }
            do {
                userState.isLoggingOut = true
                userState.isShowingLoading = true
                try logoutController.logout {
                    userState.isLoggingOut = false
                    userState.isShowingLoading = false
                    userState.currentState = .none
                }
            } catch {
                assertionFailure("Failed to deauthorize \(error)")
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
                    userState.currentState = .deleting
                    guard networkChecker.connectionAvailable else {
                        alert = InAppAlerts.unableToConnectBeforeDeletingAccount()
                        return
                    }
                    do {
                        userState.isShowingLoading = true
                        try logoutController.deleteAccount { result in
                            switch result {
                            case .success(_):
                                DispatchQueue.main.async {
                                    userState.isShowingLoading = false
                                }
                            case .failure(_):
                                alert = InAppAlerts.failedDeletingAccount()
                            }
                        }
                    } catch {
                        assertionFailure("Failed to delete account \(error)")
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
}
