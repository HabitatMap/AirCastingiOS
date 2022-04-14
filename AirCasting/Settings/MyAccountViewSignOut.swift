// Created by Lunar on 18/06/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct MyAccountViewSignOut: View {
    @State private var alert: AlertInfo?
//    @State var alertShown: AlertShownType?
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
//        .alert(item: $alertShown, content: { alertType in
//            if alertShown == .firstDeletingAlert {
//                return Alert(title: Text("Delete file"),
//                             message: Text("Are you sure?"),
//                             primaryButton: .destructive(Text("Delete")) {
//                    alertShown = .secondDeletingAlert
//                },
//                             secondaryButton: .cancel())
//            } else {
//                return Alert(title: Text("Delete file"),
//                             message: Text("Are you sure?"),
//                             primaryButton: .destructive(Text("Confirm")) {
//
//                },
//                             secondaryButton: .cancel())
//            }
//        })
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
//            self.alertShown = .firstDeletingAlert

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
                            alert = InAppAlerts.thirdConfirmationDeletingAccountAlert()
                        }
                    case .failure(_):
                        alert = InAppAlerts.failedDeletingAccount()
                    }
                }
            } catch {
                assertionFailure("Failed to delete account \(error)")
            }
        } label: {
            Text(Strings.SignOutSettings.deleteAccount)
        }
        .foregroundColor(.red)
        .padding(.bottom, 20)
        .padding()
    }
}

//enum AlertShownType : Identifiable {
//    case firstDeletingAlert
//    case secondDeletingAlert
//
//    var id : Int { get { hashValue } }
//}
