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
    @Environment(\.presentationMode) var presentationMode

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
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackButton(presentationMode: presentationMode))
    }
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
