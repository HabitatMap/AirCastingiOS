// Created by Lunar on 18/06/2021.
//

import SwiftUI
import AirCastingStyling

struct MyAccountViewSignOut: View {
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

private var logInLabel: some View {
    Text(Strings.SignOutSettings.Logged)
        .foregroundColor(.aircastingGray)
        .padding()
}

private var signOutButton: some View {
    Button(action: {
    }) {
        Group {
            HStack {
                Text(Strings.SignOutSettings.signOut)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal)
        }
    } .buttonStyle(BlueButtonStyle())
    .padding()
}

#if DEBUG
struct MyAccountViewSingOut_Previews: PreviewProvider {
    static var previews: some View {
        MyAccountViewSignOut()
    }
}
#endif
