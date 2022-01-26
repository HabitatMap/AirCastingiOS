//
//  LogoutView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import AirCastingStyling

struct SettingsView<VM: SettingsViewModel>: View {
    @StateObject var viewModel: VM
    @StateObject private var featureFlagsViewModel = FeatureFlagsViewModel.shared
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        if #available(iOS 15, *) {
            NavigationView {
                main
            }
            .fullScreenCover(isPresented: $viewModel.startSDClear) {
                CreatingSessionFlowRootView {
                    SDRestartABView(viewModel: SDRestartABViewModelDefault(urlProvider: viewModel.urlProvider,
                                                                           isSDClearProcess: viewModel.SDClearingRouteProcess),
                                    creatingSessionFlowContinues: $viewModel.startSDClear)
                }
            }
            .fullScreenCover(isPresented: $viewModel.locationScreenGo) {
                CreatingSessionFlowRootView {
                    TurnOnLocationView(creatingSessionFlowContinues: $viewModel.locationScreenGo,
                                       viewModel: TurnOnLocationViewModel(locationHandler: viewModel.locationHandler,
                                                                          bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: bluetoothManager),
                                                                          sessionContext: viewModel.sessionContext,
                                                                          urlProvider: viewModel.urlProvider,
                                                                          isSDClearProcess: viewModel.SDClearingRouteProcess))
                }
            }
            .fullScreenCover(isPresented: $viewModel.BTScreenGo) {
                CreatingSessionFlowRootView {
                    TurnOnBluetoothView(creatingSessionFlowContinues: $viewModel.BTScreenGo,
                                        sdSyncContinues: .constant(false),
                                        isSDClearProcess: viewModel.SDClearingRouteProcess,
                                        urlProvider: viewModel.urlProvider)
                }
            }
        } else {
            NavigationView {
                main
            }
            .background(
                Group {
                    EmptyView()
                        .fullScreenCover(isPresented: $viewModel.startSDClear) {
                            CreatingSessionFlowRootView {
                                SDRestartABView(viewModel: SDRestartABViewModelDefault(urlProvider: viewModel.urlProvider,
                                                                                       isSDClearProcess: viewModel.SDClearingRouteProcess),
                                                creatingSessionFlowContinues: $viewModel.startSDClear)
                            }
                        }
                    EmptyView()
                        .fullScreenCover(isPresented: $viewModel.locationScreenGo) {
                            CreatingSessionFlowRootView {
                                TurnOnLocationView(creatingSessionFlowContinues: $viewModel.locationScreenGo,
                                                   viewModel: TurnOnLocationViewModel(locationHandler: viewModel.locationHandler,                                        bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: bluetoothManager),                                    sessionContext: viewModel.sessionContext,
                                                                                      urlProvider: viewModel.urlProvider,
                                                                                      isSDClearProcess: viewModel.SDClearingRouteProcess))
                            }
                        }
                    EmptyView()
                        .fullScreenCover(isPresented: $viewModel.BTScreenGo) {
                            CreatingSessionFlowRootView {
                                TurnOnBluetoothView(creatingSessionFlowContinues: $viewModel.BTScreenGo,
                                                    sdSyncContinues: .constant(false),
                                                    isSDClearProcess: viewModel.SDClearingRouteProcess,
                                                    urlProvider: viewModel.urlProvider)
                            }
                        }
                })
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
            }
            #endif
            appInfoSection
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Strings.Settings.title)
        .environmentObject(viewModel.sessionContext)
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
            Text(Strings.Settings.betaBuild).foregroundColor(.red)
            #elseif DEBUG
            Text(Strings.Settings.debugBuild).foregroundColor(.red)
            #endif
        }.foregroundColor(.aircastingGray)
    }

    private var signOutLink: some View {
        NavigationLink(destination: MyAccountViewSignOut(logoutController: viewModel.logoutController)) {
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
            BackendSettingsView(logoutController: viewModel.logoutController,
                                urlProvider: viewModel.urlProvider)
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
