//
//  LogoutView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import Foundation

struct SettingsView: View {
    let userDefaults = UserDefaults.standard

    var body: some View {
        VStack {
            Spacer()
            Button {
                userDefaults.removeObject(forKey: UserDefaults.AUTH_TOKEN_KEY)
            } label: {
                Text("Log out")
            }.buttonStyle(BlueButtonStyle())
            
            Spacer()
        }
        .padding()
    }
}

struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
