//
//  CreateSessionView.swift
//  AirCasting
//
//  Created by Lunar on 05/02/2021.
//

import SwiftUI

struct ChooseSessionTypeView: View {
    @State private var isInfoPresented: Bool = false
    @State private var isTurnBluetoothOnLinkActive = false
    @State private var isTurnLocationOnLinkActive = false
    @State private var isPowerABLinkActive = false
    @State private var isMobileLinkActive = false
    @State private var didTapFixedSession = false
    @EnvironmentObject private var tabSelection: TabBarSelection
    var viewModel: ChooseSessionTypeViewModel
    
    var body: some View {
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
                        HStack(spacing: 60) {
                            fixedSessionButton
                            mobileSessionButton
                        }
                    }
                    Spacer()
                }
                .padding()
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
                                TurnOnBluetoothView(creatingSessionFlowContinues: $isTurnBluetoothOnLinkActive, sessionContext: viewModel.passSessionContext, urlProvider: viewModel.passURLProvider)
                            }
                        }
                    EmptyView()
                        .fullScreenCover(isPresented: $isMobileLinkActive) {
                            CreatingSessionFlowRootView {
                                SelectDeviceView(creatingSessionFlowContinues: $isMobileLinkActive, urlProvider: viewModel.passURLProvider)
                            }
                        }
                }
            )
            .onChange(of: viewModel.passBluetoothManager.centralManagerState) { _ in
                if didTapFixedSession {
                    didTapFixedSession = false
                }
            }
            .onAppear() {
                if tabSelection.selection == .createSession && tabSelection.mobileProcceding {
                    isMobileLinkActive = true
                }
            }
        }
        .environmentObject(viewModel.passSessionContext)
    }

    var titleLabel: some View {
        Text(Strings.ChooseSessionTypeView.title)
            .font(Font.moderate(size: 32,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.ChooseSessionTypeView.message)
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
    }

    var recordNewLabel: some View {
        Text(Strings.ChooseSessionTypeView.recordNew)
            .font(Font.muli(size: 14, weight: .bold))
            .foregroundColor(.aircastingDarkGray)
    }
    
    var moreInfo: some View {
        Button(action: {
            isInfoPresented = true
        }, label: {
            Text(Strings.ChooseSessionTypeView.moreInfo)
                .font(Font.moderate(size: 14))
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
            viewModel.createNewSession(isSessionFixed: false)
            switch viewModel.mobileSessionNextStep() {
            case .location: isTurnLocationOnLinkActive = true
            case .mobile: isMobileLinkActive = true
            default: return
            }
        }) {
            mobileSessionLabel
        }
    }
    
    var fixedSessionLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.ChooseSessionTypeView.fixedLabel_1)
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text(Strings.ChooseSessionTypeView.fixedLabel_2)
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
        .padding()
        .frame(maxWidth: 145, maxHeight: 145)
        .background(Color.white)
        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
    
    var mobileSessionLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.ChooseSessionTypeView.mobileLabel_1)
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text(Strings.ChooseSessionTypeView.mobileLabel_2)
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
        .padding()
        .frame(maxWidth: 145, maxHeight: 145)
        .background(Color.white)
        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
}


#if DEBUG
struct CreateSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseSessionTypeView(viewModel: ChooseSessionTypeViewModel(locationHandler: DummyDefaultLocationHandler(), bluetoothHandler: DummyDefaultBluetoothHandler(), userSettings: UserSettings(), sessionContext: CreateSessionContext(), urlProvider: DummyURLProvider(), bluetoothManager: BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())), bluetoothManagerState: BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())).centralManagerState))
            .environmentObject(BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())))
    }
}
#endif
