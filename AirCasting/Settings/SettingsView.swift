//
//  LogoutView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import Foundation

struct SettingsView: View {
    @EnvironmentObject private var userAuthenticationSession: UserAuthenticationSession

    var body: some View {
        VStack {
            Spacer()
            Button {
                do {
                    try userAuthenticationSession.deauthorize()
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
        SettingsView()
    }
}
#endif
