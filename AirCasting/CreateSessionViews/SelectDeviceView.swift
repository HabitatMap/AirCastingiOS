//
//  SelectDeviceView.swift
//  AirCasting
//
//  Created by Lunar on 07/02/2021.
//

import SwiftUI
import CoreBluetooth
import AirCastingStyling
import Resolver

struct SelectDeviceView: View {
    @State private var alert: AlertInfo?
    @State private var selected = 0
    @State private var isTurnOnBluetoothLinkActive: Bool = false
    @State private var isPowerABLinkActive: Bool = false
    @State private var isMicLinkActive: Bool = false
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @InjectedObject private var bluetoothManager: BluetoothManager
    @InjectedObject private var microphoneManager: MicrophoneManager
    @Injected private var bluetoothConnectionProtector: ConnectionProtectable
    @Binding var creatingSessionFlowContinues : Bool
    @Binding var sdSyncContinues : Bool
    @EnvironmentObject private var emptyDashboardButtonTapped: EmptyDashboardButtonTapped
    @EnvironmentObject private var tabSelection: TabBarSelection

    
    var body: some View {
        VStack(spacing: 30) {
            ProgressView(value: 0.125)
            titleLabel
            bluetoothButton
            micButton
            Spacer()
        }
        .alert(item: $alert, content: { $0.makeAlert() })
        .padding()
        .background( Group {
            NavigationLink(
                destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues),
                isActive: $isPowerABLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sdSyncContinues: $sdSyncContinues),
                isActive: $isTurnOnBluetoothLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                destination: CreateSessionDetailsView(creatingSessionFlowContinues: $creatingSessionFlowContinues),
                isActive: $isMicLinkActive,
                label: {
                    EmptyView()
                })
        })
        .onAppear() {
            selected = 0
            #warning("Handle that mobileWasTapped is somehow public")
            emptyDashboardButtonTapped.mobileWasTapped = false
        }
    }
    
    var titleLabel: some View {
        Text(Strings.SelectDeviceView.title)
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var bluetoothButton: some View {
        Button(action: {
            // it doesn't have to be airbeam, it can be any device, but it doesn't influence anything, it's just needed for views flow
            sessionContext.deviceType = DeviceType.AIRBEAM3
            selected = 1
            if CBCentralManager.authorization != .denied && bluetoothManager.centralManagerState == .poweredOn {
                isPowerABLinkActive = true
            } else {
                isTurnOnBluetoothLinkActive = true
            }
        }, label: {
            createLabel(title: Strings.SelectDeviceView.bluetoothLabel, subtitle: Strings.SelectDeviceView.bluetoothDevice)
        })
        .buttonStyle(WhiteSelectingButtonStyle(isSelected: selected == 1))
    }
    
    var micButton: some View {
        Button(action: {
            sessionContext.deviceType = DeviceType.MIC
            selected = 2
            if microphoneManager.recordPermissionGranted() {
                isMicLinkActive = true
            } else {
                microphoneManager.requestRecordPermission { isGranted in
                    DispatchQueue.main.async {
                        if isGranted {
                            isMicLinkActive = true
                        } else {
                            alert = InAppAlerts.microphonePermissionAlert()
                            selected = 0
                        }
                    }
                }
            }
        }, label: {
            createLabel(title: Strings.SelectDeviceView.micLabel_1, subtitle: Strings.SelectDeviceView.phoneMicrophone)
        })
        .buttonStyle(WhiteSelectingButtonStyle(isSelected: selected == 2))
        .disabled(microphoneManager.isRecording)
        .onTapGesture {
            alert = InAppAlerts.microphoneSessionAlreadyRecordingAlert()
        }
    }
    
    private func createLabel(title text: String, subtitle string: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                StringCustomizer.customizeString(text,
                                                 using: [string],
                                                 fontWeight: .bold,
                                                 color: .accentColor,
                                                 font: Fonts.muliBoldHeading1,
                                                 makeNewLineAfterCustomized: true)
                .font(Fonts.muliRegularHeading4)
                .foregroundColor(.aircastingGray)
            }
            
            Spacer()
            VStack {
                Image(systemName: "chevron.right")
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 20)
            }
        }
        .padding(.horizontal)
    }
}
