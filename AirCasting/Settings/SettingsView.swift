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
    @State private var isToggle: Bool = true
    @State private var showModal = false
    @EnvironmentObject var userSettings: UserSettings
    
    init(urlProvider: BaseURLProvider, logoutController: LogoutController) {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.darkBlue)]
        self.urlProvider = urlProvider
        self.logoutController = logoutController
    }
    
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
                    }.onChange(of: isToggle) { value in
                        userSettings.contributingToCrowdMap = value
                    }
                    navigateToBackendSettingsButton
                }
                Section() {
                    Text("AirCasting App v. ") + Text("\(UIApplication.appVersion!)") +
                        Text(" build: ") + Text("\(UIApplication.buildVersion!)")
                }.foregroundColor(.aircastingGray)
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Strings.Settings.title)
        }
    }
    
    private var signOutLink: some View {
        NavigationLink(destination: MyAccountViewSignOut(logoutController: logoutController)) {
            Text(Strings.Settings.myAccount)
                .font(Font.muli(size: 16, weight: .bold))
        }
    }
    
    private var crowdMapTitle: some View {
        Text(Strings.Settings.crowdMap)
            .font(Font.muli(size: 16, weight: .bold))
            .padding(.bottom, 14)
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
            .font(Font.muli(size: 16, weight: .regular))
            .foregroundColor(.aircastingGray)
    }
    
    private var navigateToBackendSettingsButton: some View {
        Button(action: {
            showModal.toggle()
        }) {
            Group {
                HStack {
                    Text(Strings.Settings.backendSettings)
                        .font(Font.muli(size: 16, weight: .bold))
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
