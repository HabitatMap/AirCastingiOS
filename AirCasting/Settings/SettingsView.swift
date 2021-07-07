//
//  LogoutView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import AirCastingStyling

struct SettingsView: View {
    let urlProvider: BaseURLProvider
    let logoutController: LogoutController
    @State private var isToggle: Bool = false
    @State private var showModal = false
    
    
    var body: some View {
        NavigationView {
            Form {
                Section() {
                    signOutLink
                }
                Section() {
                    VStack(alignment: .leading) {
                        HStack(spacing: 5) {
                            crowdMapTitle
                            crowdMapSwitch
                        }
                        Spacer()
                        crowdMapDescription
                    }
                    navigateToBackendSettingsButton
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Strings.Settings.title)
        }
    }
    
    private var signOutLink: some View {
        NavigationLink(destination: MyAccountViewSignOut(logoutController: logoutController)) {
            Text(Strings.Settings.myAccount)
        }
    }
    
    private var crowdMapTitle: some View {
        Text(Strings.Settings.crowdMap)
    }
    
    private var crowdMapSwitch: some View {
        Toggle(isOn: $isToggle){
            Text("Switch")
                .font(.title)
                .foregroundColor(Color.white)
        }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
    
    private var crowdMapDescription: some View {
        Text(Strings.Settings.crowdMapDescription)
            .fontWeight(.light)
    }
    
    private var navigateToBackendSettingsButton: some View {
        Button(action: {
            showModal.toggle()
        }) {
            Group {
                HStack {
                    Text(Strings.Settings.backendSettings)
                        .accentColor(.black)
                    Spacer()
                    Image(systemName: "control")
                        .accentColor(.gray).opacity(0.6)
                }
            }
        }.sheet(isPresented: $showModal, content: {
            BackendSettingsView(urlProvider: urlProvider)
        })
    }
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(urlProvider: DummyURLProvider(), logoutController: FakeLogoutController())
    }
}
#endif
