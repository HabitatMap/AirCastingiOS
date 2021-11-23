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
    var viewModel: ChooseSessionTypeViewModel
    var sessionSynchronizer: SessionSynchronizer
    @EnvironmentObject private var sdSyncController: SDSyncController
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject private var emptyDashboardButtonTapped: EmptyDashboardButtonTapped
    var shouldGoToChooseSessionScreen: Bool {
        (tabSelection.selection == .createSession && emptyDashboardButtonTapped.mobileWasTapped) ? true : false
    }

    var body: some View {
        if #available(iOS 15, *) {
            NavigationView {
                VStack(spacing: 50) {
                    VStack(alignment: .leading, spacing: 10) {
                        titleLabel
                        messageLabel
                    }
                    .background(Color.white)
                    .padding(.horizontal)
                
                    VStack {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                recordNewLabel
                                Spacer()
                                moreInfo
                            }
                            HStack(spacing: 25) {
                                fixedSessionButton
                                mobileSessionButton
                            }
                            Text("or")
                            sdSyncButton
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 30)
                    .background(
                        Color.aircastingBackground.opacity(0.25)
                            .ignoresSafeArea()
                    )
                }
             
                .fullScreenCover(isPresented: $isPowerABLinkActive) {
                    CreatingSessionFlowRootView {
                        PowerABView(creatingSessionFlowContinues: $isPowerABLinkActive, urlProvider: viewModel.passURLProvider)
                    }
                }
            
                .fullScreenCover(isPresented: $isTurnLocationOnLinkActive) {
                    CreatingSessionFlowRootView {
                        TurnOnLocationView(creatingSessionFlowContinues: $isTurnLocationOnLinkActive, viewModel: TurnOnLocationViewModel(locationHandler: viewModel.locationHandler, bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: viewModel.passBluetoothManager), sessionContext: viewModel.passSessionContext, urlProvider: viewModel.passURLProvider))
                    }
                }
          
                .fullScreenCover(isPresented: $isTurnBluetoothOnLinkActive) {
                    CreatingSessionFlowRootView {
                        TurnOnBluetoothView(creatingSessionFlowContinues: $isTurnBluetoothOnLinkActive, urlProvider: viewModel.passURLProvider)
                    }
                }

                .fullScreenCover(isPresented: $isMobileLinkActive) {
                    CreatingSessionFlowRootView {
                        SelectDeviceView(creatingSessionFlowContinues: $isMobileLinkActive, urlProvider: viewModel.passURLProvider)
                    }
                }
                
                .fullScreenCover(isPresented: $startSync) {
                    SDSyncRootView(sessionSynchronizer: sessionSynchronizer, sdSyncController: sdSyncController, urlProvider: viewModel.passURLProvider)
                }
                .onChange(of: viewModel.passBluetoothManager.centralManagerState) { _ in
                    if didTapFixedSession {
                        didTapFixedSession = false
                    }
                }
                .onAppear {
                    shouldGoToChooseSessionScreen ? (handleMobileSessionState()) : (isMobileLinkActive = false)
                }
                .onChange(of: tabSelection.selection, perform: { _ in
                    shouldGoToChooseSessionScreen ? (handleMobileSessionState()) : (isMobileLinkActive = false)
                })
            }
            .environmentObject(viewModel.passSessionContext)
        } else {
            NavigationView {
                VStack(spacing: 50) {
                    VStack(alignment: .leading, spacing: 10) {
                        titleLabel
                        messageLabel
                    }
                    .background(Color.white)
                    .padding(.horizontal)
                    
                    VStack {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                recordNewLabel
                                Spacer()
                                moreInfo
                            }
                            HStack(spacing: 25) {
                                fixedSessionButton
                                mobileSessionButton
                            }
                            Text("or")
                            sdSyncButton
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 30)
                    .background(
                        Color.aircastingBackground.opacity(0.25)
                            .ignoresSafeArea()
                    )
                }
                .background(
                    Group {
                        EmptyView()
                            .fullScreenCover(isPresented: $isPowerABLinkActive) {
                                CreatingSessionFlowRootView {
                                    PowerABView(creatingSessionFlowContinues: $isPowerABLinkActive, urlProvider: viewModel.passURLProvider)
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isTurnLocationOnLinkActive) {
                                CreatingSessionFlowRootView {
                                    TurnOnLocationView(creatingSessionFlowContinues: $isTurnLocationOnLinkActive, viewModel: TurnOnLocationViewModel(locationHandler: viewModel.locationHandler, bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: viewModel.passBluetoothManager), sessionContext: viewModel.passSessionContext, urlProvider: viewModel.passURLProvider))
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isTurnBluetoothOnLinkActive) {
                                CreatingSessionFlowRootView {
                                    TurnOnBluetoothView(creatingSessionFlowContinues: $isTurnBluetoothOnLinkActive, urlProvider: viewModel.passURLProvider)
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $isMobileLinkActive) {
                                CreatingSessionFlowRootView {
                                    SelectDeviceView(creatingSessionFlowContinues: $isMobileLinkActive, urlProvider: viewModel.passURLProvider)
                                }
                            }
                        EmptyView()
                            .fullScreenCover(isPresented: $startSync) {
                                SDSyncRootView(sessionSynchronizer: sessionSynchronizer, sdSyncController: sdSyncController, urlProvider: viewModel.passURLProvider)
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
                }
                .onChange(of: tabSelection.selection, perform: { _ in
                    shouldGoToChooseSessionScreen ? (handleMobileSessionState()) : (isMobileLinkActive = false)
                })
            }
            .environmentObject(viewModel.passSessionContext)
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
            case .location: isTurnLocationOnLinkActive = true
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
        Button("Sync data from AirBeam3") {
            startSync = true
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
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.ChooseSessionTypeView.fixedLabel_1)
                .font(Fonts.boldHeading1)
                .foregroundColor(.accentColor)
            Text(Strings.ChooseSessionTypeView.fixedLabel_2)
                .font(Fonts.muliHeading3)
                .foregroundColor(.aircastingGray)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: 180, maxHeight: 145)
        .background(Color.white)
        .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)
    }
    
    var mobileSessionLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.ChooseSessionTypeView.mobileLabel_1)
                .font(Fonts.boldHeading1)
                .foregroundColor(.accentColor)
            Text(Strings.ChooseSessionTypeView.mobileLabel_2)
                .font(Fonts.muliHeading3)
                .foregroundColor(.aircastingGray)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: 180, maxHeight: 145)
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
