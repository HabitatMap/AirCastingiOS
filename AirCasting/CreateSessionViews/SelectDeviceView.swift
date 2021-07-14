//
//  SelectDeviceView.swift
//  AirCasting
//
//  Created by Lunar on 07/02/2021.
//

import SwiftUI
import CoreBluetooth
import AirCastingStyling

struct SelectDeviceView: View {
    
    @State private var canContinue = false
    @State private var selected = 0
    @State private var isTurnOnBluetoothLinkActive: Bool = false
    @State private var isPowerABLinkActive: Bool = false
    @State private var isMicLinkActive: Bool = false
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject private var microphoneManager: MicrophoneManager
    @StateObject private var locationTracker = LocationTracker()
    @Binding var creatingSessionFlowContinues : Bool
    @State private var showAlert = false
    
    let urlProvider: BaseURLProvider
    
    var body: some View {
        VStack(spacing: 30) {
            ProgressView(value: 0.125)
            titleLabel
            bluetoothButton
            micButton
            Spacer()
            chooseButton
            
        }.alert(isPresented: $showAlert, content: {
            Alert(title: Text("Location alert"), message: Text("Please go to settings and allow location first!"), dismissButton: .default(Text("OK")))
        })
        .padding()
        .onAppear {
            locationTracker.requestAuthorisation()
        }
        .onChange(of: locationTracker.locationGranted.bool) { newValue in
            showAlert = !newValue
        }
    }
    
    var titleLabel: some View {
        Text("What device are you using to record this session?")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    
    var bluetoothButton: some View {
        Button(action: {
            selected = 1
            // it doesn't have to be airbeam, it can be any device, but it doesn't influence anything, it's just needed for views flow
            sessionContext.deviceType = DeviceType.AIRBEAM3
            _ = bluetoothManager.centralManager
        }, label: {
            bluetoothLabels
        })
        .buttonStyle(WhiteSelectingButtonStyle(isSelected: selected == 1))
    }
    
    var micButton: some View {
        Button(action: {
            selected = 2
            sessionContext.deviceType = DeviceType.MIC
        }, label: {
            micLabels
        })
        .buttonStyle(WhiteSelectingButtonStyle(isSelected: selected == 2))
        .disabled(microphoneManager.isRecording)
    }
    
    var bluetoothLabels: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bluetooth device")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("for example AirBeam")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var micLabels: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Phone microphone")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("to measure sound level")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var chooseButton: some View {
        Button(action: {
            if selected == 1 {
                if CBCentralManager.authorization == .allowedAlways &&
                    bluetoothManager.centralManager.state == .poweredOn {
                    isPowerABLinkActive = true
                } else {
                    isTurnOnBluetoothLinkActive = true
                }
            } else if selected == 2 {
                if microphoneManager.recordPermissionGranted() {
                    isMicLinkActive = true
                } else {
                    microphoneManager.requestRecordPermission { (isGranted) in
                        DispatchQueue.main.async {
                            if isGranted {
                                isMicLinkActive = true
                            } else {
                                SettingsManager.goToAuthSettings()
                            }
                        }
                    }
                }
            }
        }, label: {
            Text("Choose")
        })
        .disabled(!locationTracker.locationGranted.bool)
        .buttonStyle(BlueButtonStyle())
        .background( Group {
            NavigationLink(
                destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider),
                isActive: $isPowerABLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider),
                isActive: $isTurnOnBluetoothLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                destination: CreateSessionDetailsView(sessionCreator: MicrophoneSessionCreator(microphoneManager: microphoneManager), creatingSessionFlowContinues: $creatingSessionFlowContinues),
                isActive: $isMicLinkActive,
                label: {
                    EmptyView()
                })
        })
    }
}

#if DEBUG
struct SelectDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        SelectDeviceView(creatingSessionFlowContinues: .constant(true), urlProvider: DummyURLProvider())
    }
}
#endif
