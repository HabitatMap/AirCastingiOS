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
    @State private var isToggle: Bool = false
    @State private var showModal = false
    
    var body: some View {
        NavigationView {
            List {
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
                
                Section() {
                    helpLink
                    hardwareLink
                    aboutLink
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Strings.Settings.title)
        }
    }
    
    private var signOutLink: some View {
        NavigationLink(destination: MyAccountViewSignOut()) {
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
            BackendSettingsModalView()
        })
    }
    
    private var helpLink: some View {
        NavigationLink(destination: Text(Strings.Settings.settingsHelp)) {
            Text(Strings.Settings.settingsHelp)
        }
    }
    
    private var hardwareLink: some View {
        NavigationLink(destination: Text(Strings.Settings.hardwareDevelopers)) {
            Text(Strings.Settings.hardwareDevelopers)
        }
    }
    
    private var aboutLink: some View {
        NavigationLink(destination: Text(Strings.Settings.about)) {
            Text(Strings.Settings.about)
        }
    }
    
    
    private struct BackendSettingsModalView: View {
        
        @Environment(\.presentationMode) var presentationMode
        @State var url: String = ""
        @State var port: String = ""
        
        var body: some View {
            VStack(alignment: .leading) {
                title
                Spacer()
                createTextfield(placeholder: "Enter url", binding: $url)
                createTextfield(placeholder: "Enter port", binding: $port)
                Spacer()
                oKButton
                cancelButton
            }
            .padding()
        }
        
        private var title: some View {
            Text(Strings.BackendSettings.backendSettings)
                .font(.title2)
        }
        
        private var oKButton: some View {
            Button(Strings.BackendSettings.Ok) {
                presentationMode.wrappedValue.dismiss()
            }.buttonStyle(BlueButtonStyle())
        }
        
        private var cancelButton: some View {
            Button(Strings.BackendSettings.Cancel) {
                presentationMode.wrappedValue.dismiss()
            }.buttonStyle(BlueTextButtonStyle())
        }
    }
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(logoutController: FakeLogoutController())
    }
}
#endif
