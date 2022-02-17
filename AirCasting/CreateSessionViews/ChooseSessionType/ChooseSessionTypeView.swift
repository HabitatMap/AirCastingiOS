//
//  CreateSessionView.swift
//  AirCasting
//
//  Created by Lunar on 05/02/2021.
//

import SwiftUI
import AirCastingStyling

struct ChooseSessionTypeView: View {
    @State private var isInfoPresented: Bool = false
    @State private var isTurnBluetoothOnLinkActive = false
    @State private var isTurnLocationOnLinkActive = false
    @State private var isPowerABLinkActive = false
    @State private var isMobileLinkActive = false
    @State private var didTapFixedSession = false
    @State private var startSync = false
    @State private var alert: AlertInfo?
    var viewModel: ChooseSessionTypeViewModel
    var sessionSynchronizer: SessionSynchronizer
    @EnvironmentObject private var sdSyncController: SDSyncController
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject private var emptyDashboardButtonTapped: EmptyDashboardButtonTapped
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @EnvironmentObject var networkChecker: NetworkChecker
    
    var shouldGoToChooseSessionScreen: Bool {
        (tabSelection.selection == .createSession && emptyDashboardButtonTapped.mobileWasTapped) ? true : false
    }
    var shouldGoToSyncScreen: Bool {
        (tabSelection.selection == .createSession && finishAndSyncButtonTapped.finishAndSyncButtonWasTapped) ? true : false
    }
    @StateObject private var featureFlagsViewModel = FeatureFlagsViewModel.shared

    var body: some View {
        if #available(iOS 15, *) {
            NavigationView {
                mainContent
                .fullScreenCover(isPresented: $isPowerABLinkActive) {
                    CreatingSessionFlowRootView {
                        PowerABView(creatingSessionFlowContinues: $isPowerABLinkActive,
                                    urlProvider: viewModel.passURLProvider,
                                    locationHandler: viewModel.locationHandler)
                    }
                }
            
                .fullScreenCover(isPresented: $isTurnLocationOnLinkActive) {
                    CreatingSessionFlowRootView {
                        TurnOnLocationView(creatingSessionFlowContinues: $isTurnLocationOnLinkActive,
                                           viewModel: TurnOnLocationViewModel(locationHandler: viewModel.locationHandler,
                                                                              bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: viewModel.passBluetoothManager),
                                                                              sessionContext: viewModel.passSessionContext,
                                                                              urlProvider: viewModel.passURLProvider,
                                                                              isSDClearProcess: false))
                    }
                }
          
                .fullScreenCover(isPresented: $isTurnBluetoothOnLinkActive) {
                    CreatingSessionFlowRootView {
                        TurnOnBluetoothView(creatingSessionFlowContinues: $isTurnBluetoothOnLinkActive,
                                            sdSyncContinues: .constant(false),
                                            locationHandler: viewModel.locationHandler, urlProvider: viewModel.passURLProvider)
                    }
                }

                .fullScreenCover(isPresented: $isMobileLinkActive) {
                    CreatingSessionFlowRootView {
                        SelectDeviceView(creatingSessionFlowContinues: $isMobileLinkActive,
                                         sdSyncContinues: .constant(false),
                                         locationHandler: viewModel.locationHandler,
                                         urlProvider: viewModel.passURLProvider)
                    }
                }
                
                .fullScreenCover(isPresented: $startSync) {
                    CreatingSessionFlowRootView {
                        SDSyncRootView(viewModel: SDSyncRootViewModelDefault(sessionSynchronizer: sessionSynchronizer,
                                                                             urlProvider: viewModel.passURLProvider), creatingSessionFlowContinues: $startSync)
                    }
                }
                .onChange(of: viewModel.passBluetoothManager.centralManagerState) { _ in
                    if didTapFixedSession {
                        didTapFixedSession = false
                    }
                }
                .onAppear {
                    shouldGoToChooseSessionScreen ? (handleMobileSessionState()) : (isMobileLinkActive = false)
                    startSync = shouldGoToSyncScreen
                }
                .onChange(of: tabSelection.selection, perform: { _ in
                    shouldGoToChooseSessionScreen ? (handleMobileSessionState()) : (isMobileLinkActive = false)
                    startSync = shouldGoToSyncScreen
                })
            }
            .environmentObject(viewModel.passSessionContext)
        } else {
            NavigationView {
                mainContent
                .background(
                    Group {
                        EmptyView()
                            .fullScreenCover(isPresented: $isPowerABLinkActive) {
                                CreatingSessionFlowRootView {
                                    PowerABView(creatingSessionFlowContinues: $isPowerABLinkActive,
                                                urlProvider: viewModel.passURLProvider,
                                                locationHandler: viewModel.locationHandler)
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isTurnLocationOnLinkActive) {
                                CreatingSessionFlowRootView {
                                    TurnOnLocationView(creatingSessionFlowContinues: $isTurnLocationOnLinkActive,
                                                       viewModel: TurnOnLocationViewModel(locationHandler: viewModel.locationHandler, bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: viewModel.passBluetoothManager),
                                                                                          sessionContext: viewModel.passSessionContext,
                                                                                          urlProvider: viewModel.passURLProvider,
                                                                                          isSDClearProcess: false))
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isTurnBluetoothOnLinkActive) {
                                CreatingSessionFlowRootView {
                                    TurnOnBluetoothView(creatingSessionFlowContinues: $isTurnBluetoothOnLinkActive,
                                                        sdSyncContinues: .constant(false),
                                                        locationHandler: viewModel.locationHandler, urlProvider: viewModel.passURLProvider)
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isMobileLinkActive) {
                                CreatingSessionFlowRootView {
                                    SelectDeviceView(creatingSessionFlowContinues: $isMobileLinkActive,
                                                     sdSyncContinues: .constant(false),
                                                     locationHandler: viewModel.locationHandler, urlProvider: viewModel.passURLProvider)
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $startSync) {
                                CreatingSessionFlowRootView {
                                    SDSyncRootView(viewModel: SDSyncRootViewModelDefault(sessionSynchronizer: sessionSynchronizer,
                                                                                         urlProvider: viewModel.passURLProvider),
                                                   creatingSessionFlowContinues: $startSync)
                                }
                            }
                    }
                )
                .onChange(of: viewModel.passBluetoothManager.centralManagerState) { _ in
                    if didTapFixedSession {
                        didTapFixedSession = false
                    }
                }
                .onAppear {
                    shouldGoToChooseSessionScreen ? (handleMobileSessionState()) : (isMobileLinkActive = false)
                    startSync = shouldGoToSyncScreen
                }
                .onChange(of: tabSelection.selection, perform: { _ in
                    shouldGoToChooseSessionScreen ? (handleMobileSessionState()) : (isMobileLinkActive = false)
                    startSync = shouldGoToSyncScreen
                })
            }
            .environmentObject(viewModel.passSessionContext)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 50) {
            VStack(alignment: .leading, spacing: 10) {
                titleLabel
                messageLabel
            }
            .background(Color.white)
            .padding(.horizontal)
        
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    recordNewLabel
                    Spacer()
                    moreInfo
                }
                HStack {
                    fixedSessionButton
                    Spacer()
                    mobileSessionButton
                }
                Spacer()
                if featureFlagsViewModel.enabledFeatures.contains(.sdCardSync) {
                    orLabel
                    sdSyncButton
                }
                Spacer()
            }
            .padding(.bottom)
            .padding(.vertical)
            .padding(.horizontal, 30)
            .background(
                Color.aircastingBackground.opacity(0.25)
                    .ignoresSafeArea()
            )
            .alert(item: $alert, content: { $0.makeAlert() })
        }
    }

    var titleLabel: some View {
        Text(Strings.ChooseSessionTypeView.title)
            .font(Fonts.boldTitle1)
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.ChooseSessionTypeView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }

    var recordNewLabel: some View {
        Text(Strings.ChooseSessionTypeView.recordNew)
            .font(Fonts.boldHeading3)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var orLabel: some View {
        Text(Strings.ChooseSessionTypeView.orLabel)
            .font(Fonts.boldHeading3)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var moreInfo: some View {
        Button(action: {
            isInfoPresented = true
        }, label: {
            Text(Strings.ChooseSessionTypeView.moreInfo)
                .font(Fonts.regularHeading3)
                .foregroundColor(.accentColor)
        })
            .sheet(isPresented: $isInfoPresented, content: {
                MoreInfoPopupView()
            })
    }
    
    var fixedSessionButton: some View {
        Button(action: {
            viewModel.createNewSession(isSessionFixed: true)
            switch viewModel.fixedSessionNextStep() {
            case .airBeam: isPowerABLinkActive = true
            case .bluetooth: isTurnBluetoothOnLinkActive = true
            default: return
            }
        }) {
            fixedSessionLabel
        }
    }
    
    var mobileSessionButton: some View {
        Button(action: {
            handleMobileSessionState()
        }) {
            mobileSessionLabel
        }
    }
    
    var sdSyncButton: some View {
        Button(action: {
            networkChecker.connectionAvailable ? startSync.toggle() : (alert = InAppAlerts.noNetworkAlert())
        }) {
            syncButtonLabel
        }
    }
    
    func handleMobileSessionState() {
        viewModel.createNewSession(isSessionFixed: false)
        switch viewModel.mobileSessionNextStep() {
        case .location: isTurnLocationOnLinkActive = true
        case .mobile: isMobileLinkActive = true
        default: return
        }
    }
    
    var fixedSessionLabel: some View {
        chooseSessionButton(title:  StringCustomizer.customizeString(Strings.ChooseSessionTypeView.fixedLabel,
                                                                     using: [Strings.ChooseSessionTypeView.fixedSession],
                                                                     color: .accentColor,
                                                                     font: Fonts.boldHeading1))
    }
    
    var mobileSessionLabel: some View {
        chooseSessionButton(title:  StringCustomizer.customizeString(Strings.ChooseSessionTypeView.mobileLabel,
                                                                     using: [Strings.ChooseSessionTypeView.mobileSession],
                                                                     color: .accentColor,
                                                                     font: Fonts.boldHeading1))
    }
    
    var syncButtonLabel: some View {
        chooseSessionButton(title:  StringCustomizer.customizeString(Strings.ChooseSessionTypeView.syncTitle,
                                                                     using: [Strings.ChooseSessionTypeView.syncData],
                                                                     color: .accentColor,
                                                                     font: Fonts.boldHeading1,
                                                                     makeNewLineAfterCustomized: true))
    }
    
}

extension View {
    func chooseSessionButton(title: Text) -> some View {
        VStack(alignment: .leading, spacing: 10) {
                title
                .font(Fonts.muliHeading3)
                .foregroundColor(.aircastingGray)
        }
        .multilineTextAlignment(.leading)
        .padding(15)
        .frame(minWidth: (UIScreen.main.bounds.width / 2.5) < 147 ? (UIScreen.main.bounds.width / 2.5) : 147,
               maxWidth: 147,
               minHeight: (UIScreen.main.bounds.height) / 4.5 < 145 ? (UIScreen.main.bounds.height) : 145,
               maxHeight: 145,
               alignment: .leading)
        .background(Color.white)
        .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)
    }
}

#if DEBUG
struct CreateSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseSessionTypeView(viewModel: ChooseSessionTypeViewModel(locationHandler: DummyDefaultLocationHandler(), bluetoothHandler: DummyDefaultBluetoothHandler(), userSettings: UserSettings(), sessionContext: CreateSessionContext(), urlProvider: DummyURLProvider(), bluetoothManager: BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())), bluetoothManagerState: BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())).centralManagerState), sessionSynchronizer: DummySessionSynchronizer())
            .environmentObject(BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())))
    }
}
#endif
