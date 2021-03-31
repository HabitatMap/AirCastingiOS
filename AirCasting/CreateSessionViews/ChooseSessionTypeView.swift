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
    @Environment(\.managedObjectContext) var context
    @StateObject var sessionContext = CreateSessionContext()
    @State private var isTurnBluetoothOnLinkActive = false
    @State private var isPowerABLinkActive = false
    @State private var isMobileLinkActive = false
    @State private var didTapFixedSession = false
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
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
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                sessionContext.managedObjectContext = context
                if CBCentralManager.authorization == .allowedAlways {
                    _ = bluetoothManager.centralManager
                }
            }
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
        Text("Let's begin")
            .font(Font.moderate(size: 32,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("How would you like to add your session?")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
    }
    var recordNewLabel: some View {
        Text("Record a new session")
            .font(Font.muli(size: 14, weight: .bold))
            .foregroundColor(.aircastingDarkGray)
    }
    
    var moreInfo: some View {
        Button(action: {
            isInfoPresented = true
        }, label: {
            Text("more info")
                .font(Font.moderate(size: 14))
                .foregroundColor(.accentColor)
        })
        .sheet(isPresented: $isInfoPresented, content: {
            MoreInfoPopupView()
        })
    }
    
    func goToNextFixedSessionStep() {
        createNewSession(isSessionFixed: true)
        
        // This will trigger system bluetooth authorization alert
        if CBCentralManager.authorization == .notDetermined {
            _ = bluetoothManager.centralManager
            didTapFixedSession = true
        } else if CBCentralManager.authorization == .allowedAlways,
           bluetoothManager.centralManager.state == .poweredOn {
            isPowerABLinkActive = true
        } else {
            isTurnBluetoothOnLinkActive = true
        }
    }
    
    var fixedSessionButton: some View {
        Button(action: {
            goToNextFixedSessionStep()
        }) {
            fixedSessionLabel
        }
        .background(
            Group {
                EmptyView()
                    .fullScreenCover(isPresented: $isPowerABLinkActive) {
                        CreatingSessionFlowRootView {
                            PowerABView()
                        }
                    }
                EmptyView()
                    .fullScreenCover(isPresented: $isTurnBluetoothOnLinkActive) {
                        CreatingSessionFlowRootView {
                            TurnOnBluetoothView()
                        }
                    }
            }
        )
    }
    
    var mobileSessionButton: some View {
        Button(action: {
            createNewSession(isSessionFixed: false)
            isMobileLinkActive = true
        }) {
            mobileSessionLabel
        }
        .background(
            EmptyView()
                .fullScreenCover(isPresented: $isMobileLinkActive) {
                    CreatingSessionFlowRootView {
                        SelectDeviceView()
                    }
                })
    }
    
    var fixedSessionLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fixed session")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("for measuring in one place")
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
            Text("Mobile session")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("for moving around")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
        .padding()
        .frame(maxWidth: 145, maxHeight: 145)
        .background(Color.white)
        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
    }
    
    private func createNewSession(isSessionFixed: Bool) {
        sessionContext.sessionUUID = UUID().uuidString
        if isSessionFixed {
            sessionContext.sessionType = SessionType.FIXED
        } else {
            sessionContext.sessionType = SessionType.MOBILE
        }
    }
}

struct CreateSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseSessionTypeView()
    }
}
