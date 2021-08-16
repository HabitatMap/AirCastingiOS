// Created by Lunar on 18/06/2021.
//

import SwiftUI
import AirCastingStyling

struct MyAccountViewSignOut: View {
    let logoutController: LogoutController
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var persistenceController: PersistenceController

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                #warning("Logic needs to be finished - handle name displayed")
                logInLabel
                signOutButton
                Spacer()
            }
        }
        .navigationTitle(Strings.SignOutSettings.title)
    }
}

private extension MyAccountViewSignOut {
    var logInLabel: some View {
        Text(Strings.SignOutSettings.Logged + "\(KeychainStorage(service:  Bundle.main.bundleIdentifier!).getUsername())")
            .foregroundColor(.aircastingGray)
            .font(Font.muli(size: 16))
            .padding()
    }
    
    var signOutButton: some View {
        Button(action: {
            fatalError("CRASHLYTICS TEST")
//            do {
//                try logoutController.logout()
//            } catch {
//                assertionFailure("Failed to deauthorize \(error)")
//            }
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

#if DEBUG
struct MyAccountViewSingOut_Previews: PreviewProvider {
    static var previews: some View {
        MyAccountViewSignOut(logoutController: FakeLogoutController())
    }
}
#endif
