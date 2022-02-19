//
//  LogoutView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    @InjectedObject private var userSettings: UserSettings
    @InjectedObject private var bluetoothManager: BluetoothManager
    private let sessionContext: CreateSessionContext
    #if DEBUG || BETA
    @StateObject private var shareLogsViewModel = ShareLogsViewModel()
    #endif
    
    init(sessionContext: CreateSessionContext) {
        self.sessionContext = sessionContext
        self._viewModel = .init(wrappedValue: .init(sessionContext: sessionContext))
    }

    var body: some View {
        if #available(iOS 15, *) {
            NavigationView {
                main
            }
            .fullScreenCover(isPresented: $viewModel.startSDClear) {
                CreatingSessionFlowRootView {
                    SDRestartABView(isSDClearProcess: viewModel.SDClearingRouteProcess,
                                    creatingSessionFlowContinues: $viewModel.startSDClear)
                }
            }
            .fullScreenCover(isPresented: $viewModel.locationScreenGo) {
                CreatingSessionFlowRootView {
                    TurnOnLocationView(creatingSessionFlowContinues: $viewModel.locationScreenGo,
                                       viewModel: TurnOnLocationViewModel(sessionContext: sessionContext, isSDClearProcess: viewModel.SDClearingRouteProcess))
                }
            }
            .fullScreenCover(isPresented: $viewModel.BTScreenGo) {
                CreatingSessionFlowRootView {
                    TurnOnBluetoothView(creatingSessionFlowContinues: $viewModel.BTScreenGo,
                                        sdSyncContinues: .constant(false),
                                        isSDClearProcess: viewModel.SDClearingRouteProcess)
                }
            }
            .environmentObject(viewModel.sessionContext)
            #if BETA || DEBUG
            .sheet(isPresented: $shareLogsViewModel.shareSheetPresented) {
                ActivityViewController(sharingFile: true, itemToShare: shareLogsViewModel.file!, servicesToShareItem: nil) { _,_,_,_ in
                    shareLogsViewModel.sharingFinished()
                }
            }
            #endif
        } else {
            NavigationView {
                main
            }
            .background(
                Group {
                    EmptyView()
                        .fullScreenCover(isPresented: $viewModel.startSDClear) {
                            CreatingSessionFlowRootView {
                                SDRestartABView(isSDClearProcess: viewModel.SDClearingRouteProcess,
                                                creatingSessionFlowContinues: $viewModel.startSDClear)
                            }
                        }
                    EmptyView()
                        .fullScreenCover(isPresented: $viewModel.locationScreenGo) {
                            CreatingSessionFlowRootView {
                                TurnOnLocationView(creatingSessionFlowContinues: $viewModel.locationScreenGo,
                                                   viewModel: TurnOnLocationViewModel(sessionContext: sessionContext, isSDClearProcess: viewModel.SDClearingRouteProcess))
                            }
                        }
                    EmptyView()
                        .fullScreenCover(isPresented: $viewModel.BTScreenGo) {
                            CreatingSessionFlowRootView {
                                TurnOnBluetoothView(creatingSessionFlowContinues: $viewModel.BTScreenGo,
                                                    sdSyncContinues: .constant(false),
                                                    isSDClearProcess: viewModel.SDClearingRouteProcess)
                            }
                        }
                })
            .environmentObject(viewModel.sessionContext)
            #if BETA || DEBUG
            .sheet(isPresented: $shareLogsViewModel.shareSheetPresented) {
                ActivityViewController(sharingFile: true, itemToShare: shareLogsViewModel.file!, servicesToShareItem: nil) { _,_,_,_ in
                    shareLogsViewModel.sharingFinished()
                }
            }
            #endif
        }
    }

    private var main: some View {
        Form {
            Section() {
                signOutLink
            }
            settingsSection
            #if BETA || DEBUG
            Section() {
                navigateToAppConfigurationButton
                shareLogsButton
            }
            #endif
            appInfoSection
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Strings.Settings.title)
    }

    private var settingsSection: some View {
        Section() {
            VStack(alignment: .leading) {
                crowdMapSwitch
                Spacer()
                crowdMapDescription
            }
            if featureFlagsViewModel.enabledFeatures.contains(.locationlessSessions) {
                VStack(alignment: .leading) {
                    disableMappingSwitch
                    Spacer()
                    disableMappingDescription
                }
            }
            keepScreenOnSwitch
            VStack(alignment: .leading) {
                temperatureSwitch
                Spacer()
                temperatureDescription
            }
            if featureFlagsViewModel.enabledFeatures.contains(.sdCardSync) {
                clearSDCard
            }
            navigateToBackendSettingsButton
        }
    }

    private var appInfoSection: some View {
        Section() {
            Text(Strings.Settings.appInfoTitle) + Text(". ") + Text("\(UIApplication.appVersion!) ") +
            Text(Strings.Settings.buildText) + Text(": ") + Text("\(UIApplication.buildVersion!)")
            #if BETA
            Text("Beta build").foregroundColor(.red)
            #elseif DEBUG
            Text("Debug build").foregroundColor(.red)
            #endif
        }.foregroundColor(.aircastingGray)
    }

    private var signOutLink: some View {
        NavigationLink(destination: MyAccountViewSignOut()) {
            Text(Strings.Settings.myAccount)
                .font(Fonts.boldHeading1)
        }
    }

    private var keepScreenOnSwitch: some View {
        settingSwitch(toogle: $userSettings.keepScreenOn,
                      label: Strings.Settings.keepScreenTitle)
    }

    private var crowdMapSwitch: some View {
        settingSwitch(toogle: $userSettings.contributingToCrowdMap,
                      label: Strings.Settings.crowdMap)
    }

    private var crowdMapDescription: some View {
        Text(Strings.Settings.crowdMapDescription)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }

    private var disableMappingSwitch: some View {
        settingSwitch(toogle: $userSettings.disableMapping,
                      label: Strings.Settings.disableMapping)
    }
    
    private var disableMappingDescription: some View {
        Text(Strings.Settings.disableMappingDescription)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    private var temperatureSwitch: some View {
        settingSwitch(toogle: $userSettings.convertToCelsius,
                      label: Strings.Settings.temperature)
    }

    private var temperatureDescription: some View {
        Text(Strings.Settings.celsiusDescription)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
    }

    private var navigateToBackendSettingsButton: some View {
        Button(action: {
            viewModel.navigateToBackendButtonTapped()
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
        }.sheet(isPresented: $viewModel.showBackendSettings, content: {
            BackendSettingsView()
        })
    }

    private var clearSDCard: some View {
        Button {
            viewModel.clearSDButtonTapped()
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
    
    private var shareLogsButton: some View {
        Button("Share logs") {
            shareLogsViewModel.shareLogsButtonTapped()
        }
    }
    #endif
}

extension SettingsView {
    func settingSwitch(toogle using: Binding<Bool>, label with: String) -> some View {
        Toggle(isOn: using, label: {
            Text(with)
                .font(Fonts.boldHeading1)
                .multilineTextAlignment(.leading)
        }).toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
}
