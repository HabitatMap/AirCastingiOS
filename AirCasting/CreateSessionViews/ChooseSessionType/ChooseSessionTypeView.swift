//
//  CreateSessionView.swift
//  AirCasting
//
//  Created by Lunar on 05/02/2021.
//

import SwiftUI
import CoreBluetooth

struct ChooseSessionTypeView: View {
    @State private var isInfoPresented: Bool = false
    @StateObject var sessionContext: CreateSessionContext
    @State private var isTurnBluetoothOnLinkActive = false
    @State private var isTurnLocationOnLinkActive = false
    @State private var isPowerABLinkActive = false
    @State private var isMobileLinkActive = false
    @State private var didTapFixedSession = false
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject private var locationTracker: LocationTracker
    @EnvironmentObject var userRedirectionSettings: DefaultSettingsRedirection
    @EnvironmentObject var userSettings: UserSettings
    let urlProvider: BaseURLProvider
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
                                PowerABView(creatingSessionFlowContinues: $isPowerABLinkActive, urlProvider: urlProvider)
                            }
                        }
                    EmptyView()
                        .fullScreenCover(isPresented: $isTurnLocationOnLinkActive) {
                            CreatingSessionFlowRootView {
                                TurnOnLocationView(creatingSessionFlowContinues: $isTurnLocationOnLinkActive, sessionContext: sessionContext, urlProvider: urlProvider)
                            }
                        }
                    EmptyView()
                        .fullScreenCover(isPresented: $isTurnBluetoothOnLinkActive) {
                            CreatingSessionFlowRootView {
                                TurnOnBluetoothView(creatingSessionFlowContinues: $isTurnBluetoothOnLinkActive, sessionContext: sessionContext, urlProvider: urlProvider)
                            }
                        }
                    EmptyView()
                        .fullScreenCover(isPresented: $isMobileLinkActive) {
                            CreatingSessionFlowRootView {
                                SelectDeviceView(creatingSessionFlowContinues: $isMobileLinkActive, urlProvider: urlProvider)
                            }
                        }
                }
            )
            .onChange(of: bluetoothManager.centralManagerState) { (state) in
                if didTapFixedSession {
                    goToNextFixedSessionStep()
                    didTapFixedSession = false
                }
            }
        }
        .environmentObject(sessionContext)
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
    
    func goToNextFixedSessionStep() {
        createNewSession(isSessionFixed: true)
    }
    
    var fixedSessionButton: some View {
        Button(action: {
            goToNextFixedSessionStep()
            switch viewModel.fixSessionNextStep() {
            case .AB: isPowerABLinkActive = true
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
            createNewSession(isSessionFixed: false)
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
    
    private func createNewSession(isSessionFixed: Bool) {
        sessionContext.sessionUUID = SessionUUID()
        if isSessionFixed {
            sessionContext.contribute = true
            sessionContext.sessionType = SessionType.fixed
        } else {
            sessionContext.contribute = userSettings.contributingToCrowdMap
            sessionContext.sessionType = SessionType.mobile
        }
    }
}

//#if DEBUG
//struct CreateSessionView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChooseSessionTypeView(
//            sessionContext: CreateSessionContext(), urlProvider: DummyURLProvider())
//            .environmentObject(BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())))
//    }
//}
//#endif
