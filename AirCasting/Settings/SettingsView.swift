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
    @State private var showModal = false
    @EnvironmentObject var userSettings: UserSettings
    
    init(urlProvider: BaseURLProvider, logoutController: LogoutController) {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.darkBlue),
                                                     .font: Fonts.navBarSystemFont]
        self.urlProvider = urlProvider
        self.logoutController = logoutController
    }
    
    var body: some View {
        NavigationView {
            Form {
                signOutSection
                settingsSection
                appInfoSection
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Strings.Settings.title)
        }
    }
    
    private var signOutSection: some View {
        Section() {
            signOutLink
        }
    }
    
    private var settingsSection: some View {
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
    
    private var appInfoSection: some View {
        Section() {
            Text("AirCasting App v. ") + Text("\(UIApplication.appVersion!)") +
                Text(" build: ") + Text("\(UIApplication.buildVersion!)")
        }.foregroundColor(.aircastingGray)
    }
    
    private var signOutLink: some View {
        NavigationLink(destination: MyAccountViewSignOut(logoutController: logoutController)) {
            Text(Strings.Settings.myAccount)
                .font(Fonts.boldHeading1)
        }
    }
    
    private var crowdMapTitle: some View {
        Text(Strings.Settings.crowdMap)
            .font(Fonts.boldHeading1)
            .multilineTextAlignment(.leading)
    }
    
    private var crowdMapSwitch: some View {
        Toggle(isOn: $userSettings.contributingToCrowdMap) {
        }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
    
    private var crowdMapDescription: some View {
        Text(Strings.Settings.crowdMapDescription)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    private var navigateToBackendSettingsButton: some View {
        Button(action: {
            showModal.toggle()
        }) {
            Group {
                HStack {
                    Text(Strings.Settings.backendSettings)
                        .font(Fonts.boldHeading1)
                        .accentColor(.black)
                    Spacer()
                    Image(systemName: "control")
                        .accentColor(.gray).opacity(0.6)
                }
            }
        }.sheet(isPresented: $showModal, content: {
            BackendSettingsView(logoutController: logoutController,
                                urlProvider: urlProvider)
        })
    }
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(urlProvider: DummyURLProvider(),
                     logoutController: FakeLogoutController())
    }
}
#endif
