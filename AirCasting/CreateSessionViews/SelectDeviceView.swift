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
    let locationTracker: LocationTracker
    @State private var canContinue = false
    @State private var selected = 0
    @State private var isTurnOnBluetoothLinkActive: Bool = false
    @State private var isPowerABLinkActive: Bool = false
    @State private var isMicLinkActive: Bool = false
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject private var microphoneManager: MicrophoneManager
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
            
        }.alert(isPresented: $showAlert) {
            Alert.locationAlert
        }
        .padding()
        .background( Group {
            NavigationLink(
                destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider, locationTracker: locationTracker),
                isActive: $isPowerABLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sessionContext: sessionContext, urlProvider: urlProvider, locationTracker: locationTracker),
                isActive: $isTurnOnBluetoothLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                destination: CreateSessionDetailsView(sessionCreator: MicrophoneSessionCreator(microphoneManager: microphoneManager), locationTracker: locationTracker, creatingSessionFlowContinues: $creatingSessionFlowContinues),
                isActive: $isMicLinkActive,
                label: {
                    EmptyView()
                })
        })
    }
    
    var titleLabel: some View {
        Text(Strings.SelectDeviceView.title)
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    
    var bluetoothButton: some View {
        Button(action: {
            selected = 1
            // it doesn't have to be airbeam, it can be any device, but it doesn't influence anything, it's just needed for views flow
            sessionContext.deviceType = DeviceType.AIRBEAM3
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
    }
    
    var bluetoothLabels: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.SelectDeviceView.bluetoothLabel_1)
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text(Strings.SelectDeviceView.bluetoothLabel_2)
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var micLabels: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.SelectDeviceView.micLabel_1)
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text(Strings.SelectDeviceView.micLabel_2)
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var chooseButton: some View {
        Button(action: {
            if selected == 1 {
                if CBCentralManager.authorization != .denied && bluetoothManager.centralManagerState == .poweredOn {
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
            Text(Strings.SelectDeviceView.chooseButton)
        })
        .buttonStyle(BlueButtonStyle())
    }
}

#if DEBUG
struct SelectDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        SelectDeviceView(locationTracker: DummyLocationTrakcer(), creatingSessionFlowContinues: .constant(true), urlProvider: DummyURLProvider())
    }
}
#endif
