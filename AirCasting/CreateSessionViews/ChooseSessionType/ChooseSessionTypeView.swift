//
//  CreateSessionView.swift
//  AirCasting
//
//  Created by Lunar on 05/02/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

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
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject private var emptyDashboardButtonTapped: EmptyDashboardButtonTapped
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @Injected private var networkChecker: NetworkChecker
    @InjectedObject private var bluetoothManger: BluetoothManager //TODO: Fix this (see usage) - move to VM
    
    var shouldGoToChooseSessionScreen: Bool {
        (tabSelection.selection == .createSession && emptyDashboardButtonTapped.mobileWasTapped) ? true : false
    }
    var shouldGoToSyncScreen: Bool {
        (tabSelection.selection == .createSession && finishAndSyncButtonTapped.finishAndSyncButtonWasTapped) ? true : false
    }
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel

    var body: some View {
        if #available(iOS 15, *) {
            NavigationView {
                mainContent
                .fullScreenCover(isPresented: $isPowerABLinkActive) {
                    CreatingSessionFlowRootView {
                        PowerABView(creatingSessionFlowContinues: $isPowerABLinkActive)
                    }
                }
            
                .fullScreenCover(isPresented: $isTurnLocationOnLinkActive) {
                    CreatingSessionFlowRootView {
                        TurnOnLocationView(creatingSessionFlowContinues: $isTurnLocationOnLinkActive,
                                           viewModel: TurnOnLocationViewModel(sessionContext: viewModel.passSessionContext,
                                                                              isSDClearProcess: false))
                    }
                }
          
                .fullScreenCover(isPresented: $isTurnBluetoothOnLinkActive) {
                    CreatingSessionFlowRootView {
                        TurnOnBluetoothView(creatingSessionFlowContinues: $isTurnBluetoothOnLinkActive, sdSyncContinues: .constant(false))
                    }
                }

                .fullScreenCover(isPresented: $isMobileLinkActive) {
                    CreatingSessionFlowRootView {
                        SelectDeviceView(creatingSessionFlowContinues: $isMobileLinkActive, sdSyncContinues: .constant(false))
                    }
                }
                
                .fullScreenCover(isPresented: $startSync) {
                    CreatingSessionFlowRootView {
                        SDSyncRootView(creatingSessionFlowContinues: $startSync)
                    }
                }
                // TODO: What is that??? Move to VM!
                .onChange(of: bluetoothManger.centralManagerState) { _ in
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
                                    PowerABView(creatingSessionFlowContinues: $isPowerABLinkActive)
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isTurnLocationOnLinkActive) {
                                CreatingSessionFlowRootView {
                                    TurnOnLocationView(creatingSessionFlowContinues: $isTurnLocationOnLinkActive,
                                                       viewModel: TurnOnLocationViewModel(sessionContext: viewModel.passSessionContext,
                                                                                          isSDClearProcess: false))
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isTurnBluetoothOnLinkActive) {
                                CreatingSessionFlowRootView {
                                    TurnOnBluetoothView(creatingSessionFlowContinues: $isTurnBluetoothOnLinkActive,
                                                        sdSyncContinues: .constant(false))
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isMobileLinkActive) {
                                CreatingSessionFlowRootView {
                                    SelectDeviceView(creatingSessionFlowContinues: $isMobileLinkActive,
                                                     sdSyncContinues: .constant(false))
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $startSync) {
                                CreatingSessionFlowRootView {
                                    SDSyncRootView(creatingSessionFlowContinues: $startSync)
                                }
                            }
                    }
                )
                // TODO: What is that??? Move to VM!
                .onChange(of: bluetoothManger.centralManagerState) { _ in
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
