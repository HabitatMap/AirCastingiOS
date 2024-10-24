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
    @InjectedObject private var notificationService: NotificationsManager
    private let sessionContext: CreateSessionContext
    #if BETA
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
            .navigationViewStyle(.stack)
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
            #if BETA
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
            #if BETA
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
            Group {
                Section() {
                    signOutLink
                }
                settingsSection
                #if BETA || DEBUG
                Section() {
                    navigateToAppConfigurationButton
                    #if BETA
                    shareLogsButton
                    #endif
                    Text(Strings.Settings.crashlyticsSectionTitle)
                    crashButton
                    createErrorButton
                }
                #endif
                appInfoSection
            }
            .listRowBackground(Color.listBackgroundColor)
        }
        .onAppear {
            UITableView.appearance().backgroundColor = UIColor(Color.formBackgroundColor)
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Strings.Settings.title)
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
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
            VStack(alignment: .leading) {
                dormantSessionsAlertSwitch
                Spacer()
                dormantSessionsAlertDescription
            }
            darkThemeSwitch
            keepScreenOnSwitch
            satelliteMapSwitch
            twentyFourHourFormatSwitch
            syncOnlyThroughWifiSwitch
            VStack(alignment: .leading) {
                temperatureSwitch
                Spacer()
                temperatureDescription
            }
            Group {
                if featureFlagsViewModel.enabledFeatures.contains(.sdCardSync) {
                    clearSDCard
                }
                if featureFlagsViewModel.enabledFeatures.contains(.microphoneCalibration) {
                    calibrateMicrophone
                }
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
        NavigationLink(destination: SettingsMyAccountView(viewModel: SettingsMyAccountViewModel())) {
            myAccount
        }
    }
    
    private var usernameText: some View {
        Text(viewModel.username)
            .font(Fonts.muliRegularHeading3)
            .foregroundColor(.aircastingGray)
    }
    
    private var myAccount: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.Settings.myAccount)
                .font(Fonts.muliBoldHeading1)
                .padding(.top, 5)
            usernameText
        }
    }
    
    private var satelliteMapSwitch: some View {
        settingSwitch(toogle: $userSettings.satteliteMap,
                      label: Strings.Settings.satelliteMap)
    }
    
    private var twentyFourHourFormatSwitch: some View {
        settingSwitch(toogle: $userSettings.twentyFourHour,
                      label: Strings.Settings.twentyFourHourFormat)
    }
    
    private var syncOnlyThroughWifiSwitch: some View {
        settingSwitch(toogle: $userSettings.syncOnlyThroughWifi,
                      label: Strings.Settings.syncOnlyThroughWifi)
    }
    
    private var keepScreenOnSwitch: some View {
        settingSwitch(toogle: $userSettings.keepScreenOn,
                      label: Strings.Settings.keepScreenTitle)
    }
    
    private var darkThemeSwitch: some View {
        settingSwitch(toogle: $userSettings.darkTheme,
                      label: Strings.Settings.useDarkTheme)
    }
    
    private var crowdMapSwitch: some View {
        settingSwitch(toogle: $userSettings.contributingToCrowdMap,
                      label: Strings.Settings.crowdMap)
    }
    
    private var crowdMapDescription: some View {
        Text(Strings.Settings.crowdMapDescription)
            .font(Fonts.muliRegularHeading3)
            .foregroundColor(.aircastingGray)
    }
    
    private var disableMappingSwitch: some View {
        settingSwitch(toogle: $userSettings.disableMapping,
                      label: Strings.Settings.disableMapping)
    }
    
    private var disableMappingDescription: some View {
        Text(Strings.Settings.disableMappingDescription)
            .font(Fonts.muliRegularHeading3)
            .foregroundColor(.aircastingGray)
    }
    
    
    private var dormantSessionsAlertSwitch: some View {
        settingSwitch(toogle: .init(get: { viewModel.dormantAlert },
                                    set: { viewModel.dormantStreamAlertSettingChanged(to: $0) }),
                      label: Strings.Settings.dormantSessionsAlert)
    }
    
    private var dormantSessionsAlertDescription: some View {
        Text(Strings.Settings.dormantSessionsAlertDescription)
            .font(Fonts.muliRegularHeading3)
            .foregroundColor(.aircastingGray)
    }
    
    private var temperatureSwitch: some View {
        settingSwitch(toogle: $userSettings.convertToCelsius,
                      label: Strings.Settings.temperature)
    }
    
    private var temperatureDescription: some View {
        Text(Strings.Settings.celsiusDescription)
            .font(Fonts.muliRegularHeading3)
            .foregroundColor(.aircastingGray)
    }
    
    private var navigateToBackendSettingsButton: some View {
        Button(action: {
            viewModel.navigateToBackendButtonTapped()
        }) {
            Group {
                HStack {
                    Text(Strings.Settings.backendSettings)
                        .font(Fonts.muliBoldHeading1)
                        .accentColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
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
                        .font(Fonts.muliBoldHeading1)
                        .accentColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .accentColor(.gray).opacity(0.6)
                }
            }
        }
    }
    
    private var calibrateMicrophone: some View {
        Button(action: {
            viewModel.manualMicrophoneCalibrationTapped()
        }) {
            VStack(alignment: .leading) {
                buttonCell(title: Strings.MicrophoneCalibration.settingsItemTitle)
                Spacer()
                Text(Strings.MicrophoneCalibration.settingsItemDescription)
                    .font(Fonts.muliRegularHeading3)
                    .foregroundColor(.aircastingGray)
                    .multilineTextAlignment(.leading)
            }
        }
        .sheet(isPresented: $viewModel.showMicrophoneManualCalibation, content: {
            MicrophoneManualCalibrationView { viewModel.showMicrophoneManualCalibation = false }
        })
    }

    #if DEBUG || BETA
    private var navigateToAppConfigurationButton: some View {
        NavigationLink(Strings.Settings.appConfig, destination: {
            AppConfigurationView()
                .navigationTitle(Strings.Settings.appConfig)
        })
        .font(Fonts.muliBoldHeading1)
    }
    
    #if BETA
    private var shareLogsButton: some View {
        Button(Strings.Settings.shareLogs) {
            shareLogsViewModel.shareLogsButtonTapped()
        }
    }
    #endif
    
    private var crashButton: some View {
        Button(Strings.Settings.crashTheApp) {
            let numbers = [0]
            _ = numbers[1]
        }
    }
    
    private var createErrorButton: some View {
        Button(Strings.Settings.generateError) {
            Log.error("Error induced")
        }
    }
    #endif
}

extension SettingsView {
    func buttonCell(title: String) -> some View {
        Group {
            HStack {
                Text(title)
                    .font(Fonts.muliBoldHeading1)
                    .accentColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .accentColor(.gray).opacity(0.6)
            }
        }
    }
    
    func settingSwitch(toogle using: Binding<Bool>, label with: String) -> some View {
        Toggle(isOn: using, label: {
            Text(with)
                .font(Fonts.muliBoldHeading1)
                .multilineTextAlignment(.leading)
        }).toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
}
