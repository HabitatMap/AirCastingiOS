//
//  LogoutView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import AirCastingStyling

struct SettingsView: View {
    var viewModel: SettingsViewModel
    let urlProvider: BaseURLProvider
    let logoutController: LogoutController
    let sessionContext = CreateSessionContext()
    @State private var showBackendSettings = false
    @State private var startSDClear = false
    @State private var BTScreenGo = false
    @State private var LocationScreenGo = false
    private var SDClearingRouteProcess = true
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    init(urlProvider: BaseURLProvider, logoutController: LogoutController, viewModel: SettingsViewModel) {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.darkBlue),
                                                     .font: Fonts.navBarSystemFont]
        self.urlProvider = urlProvider
        self.logoutController = logoutController
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            Form {
                signOutSection
                settingsSection
                #if BETA || DEBUG
                Section() {
                    navigateToAppConfigurationButton
                }
                #endif
                appInfoSection
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Strings.Settings.title)
        }
        .fullScreenCover(isPresented: $startSDClear) {
            CreatingSessionFlowRootView {
                SDRestartABView(viewModel: SDRestartABViewModelDefault(urlProvider: urlProvider, isSDClearProcess: SDClearingRouteProcess), creatingSessionFlowContinues: $startSDClear)
            }
        }
        .fullScreenCover(isPresented: $LocationScreenGo) {
            CreatingSessionFlowRootView {
                TurnOnLocationView(creatingSessionFlowContinues: $LocationScreenGo, isSDClearProcess: SDClearingRouteProcess, viewModel: TurnOnLocationViewModel(locationHandler: viewModel.locationHandler, bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: bluetoothManager), sessionContext: viewModel.sessionContext, urlProvider: urlProvider))
            }
        }
        .fullScreenCover(isPresented: $BTScreenGo) {
            CreatingSessionFlowRootView {
                TurnOnBluetoothView(creatingSessionFlowContinues: $BTScreenGo, sdSyncContinues: .constant(false), isSDClearProcess: SDClearingRouteProcess, urlProvider: urlProvider)
            }
        }
        .environmentObject(viewModel.sessionContext)
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
            clearSDCard
            navigateToBackendSettingsButton
        }
    }
    
    private var appInfoSection: some View {
        Section() {
            Text(Strings.Settings.appInfoTitle) + Text(". ") + Text("\(UIApplication.appVersion!)") +
            Text(Strings.Settings.buildText) + Text(": ") + Text("\(UIApplication.buildVersion!)")
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
    
    private var clearSDCard: some View {
        Button {
            switch viewModel.nextStep() {
            case .bluetooth: BTScreenGo.toggle()
            case .location: LocationScreenGo.toggle()
            case .airBeam, .mobile:
                startSDClear.toggle()
            }
         } label: {
             Group {
                 HStack {
                     Text(Strings.Settings.clearSDTitle)
                         .font(Fonts.boldHeading1)
                         .accentColor(.black)
                     Spacer()
                     Image(systemName: "chevron.right")
                         .accentColor(.gray).opacity(0.6)
                 }
             }
         }
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
                     logoutController: FakeLogoutController(),
                     viewModel: DummySettingsViewModelDefault())
    }
}
#endif
