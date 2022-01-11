// Created by Lunar on 18/06/2021.
//

import SwiftUI
import AirCastingStyling

struct MyAccountViewSignOut: View {
    let logoutController: LogoutController
    @State private var alert: AlertInfo?
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject private var userState: UserState
    @EnvironmentObject var networkChecker: NetworkChecker
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                logInLabel
                signOutButton
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
            guard networkChecker.connectionAvailable else {
                alert = InAppAlerts.unableToLogOutAlert()
                return
            }
            do {
                userState.isLoggingOut = true
                try logoutController.logout { userState.isLoggingOut = false }
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
}
