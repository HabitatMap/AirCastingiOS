//
//  LogoutView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import Foundation

struct SettingsView: View {
    let logoutController: LogoutController

    var body: some View {
        VStack {
            Spacer()
            Button {
                do {
                    try logoutController.logout()
                } catch {
                    assertionFailure("Failed to deauthorize \(error)")
                }
            } label: {
                Text("Log out")
            }.buttonStyle(BlueButtonStyle())
            
            Spacer()
        }
        .padding()
    }
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(logoutController: FakeLogoutController())
    }
}
#endif
