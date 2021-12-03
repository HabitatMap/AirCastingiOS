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
    @State private var showBackendSettings = false
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
                crowdMapSwitch
                Spacer()
                crowdMapDescription
            }
            keepScreenOnSwitch
            navigateToBackendSettingsButton
            #if BETA || DEBUG
            navigateToAppConfigurationButton
            #endif
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
    
    private var keepScreenOnSwitch: some View {
        Toggle(isOn: $userSettings.keepScreenOn, label: {
            Text(Strings.Settings.keepScreenTitle)
                .font(Fonts.boldHeading1)
        }).toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
    
    private var crowdMapSwitch: some View {
        Toggle(isOn: $userSettings.contributingToCrowdMap, label: {
            Text(Strings.Settings.crowdMap)
                .font(Fonts.boldHeading1)
                .multilineTextAlignment(.leading)
        }).toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
    
    private var crowdMapDescription: some View {
        Text(Strings.Settings.crowdMapDescription)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    private var navigateToBackendSettingsButton: some View {
        Button(action: {
            showBackendSettings.toggle()
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
        }.sheet(isPresented: $showBackendSettings, content: {
            BackendSettingsView(logoutController: logoutController,
                                urlProvider: urlProvider)
        })
    }
    
    #if DEBUG || BETA
    private var navigateToAppConfigurationButton: some View {
        NavigationLink("App config", destination: {
            AppConfigurationView()
                .navigationTitle("App config")
        })
            .font(Fonts.boldHeading1)
    }
    #endif
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(urlProvider: DummyURLProvider(),
                     logoutController: FakeLogoutController())
    }
}
#endif
