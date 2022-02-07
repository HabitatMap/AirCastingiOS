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
    @State private var alert: AlertInfo?
    @State private var selected = 0
    @State private var isTurnOnBluetoothLinkActive: Bool = false
    @State private var isPowerABLinkActive: Bool = false
    @State private var isMicLinkActive: Bool = false
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject private var microphoneManager: MicrophoneManager
    @Binding var creatingSessionFlowContinues : Bool
    @Binding var sdSyncContinues : Bool
    @State private var showAlert = false
    let locationHandler: LocationHandler
    @EnvironmentObject private var emptyDashboardButtonTapped: EmptyDashboardButtonTapped
    @EnvironmentObject private var tabSelection: TabBarSelection

    let urlProvider: BaseURLProvider
    
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
                destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider, locationHandler: locationHandler),
                isActive: $isPowerABLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sdSyncContinues: $sdSyncContinues, locationHandler: locationHandler, urlProvider: urlProvider),
                isActive: $isTurnOnBluetoothLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                destination: CreateSessionDetailsView(creatingSessionFlowContinues: $creatingSessionFlowContinues, baseURL: urlProvider, locationHandler: locationHandler),
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
            .font(Fonts.boldTitle3)
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
            bluetoothLabels
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
            micLabels
        })
        .buttonStyle(WhiteSelectingButtonStyle(isSelected: selected == 2))
    }
    
    var bluetoothLabels: some View {
        VStack(alignment: .leading, spacing: 6) {
            StringCustomizer.customizeString(Strings.SelectDeviceView.bluetoothLabel,
                            using: [Strings.SelectDeviceView.bluetoothDevice],
                            fontWeight: .bold,
                            color: .accentColor,
                            font: Fonts.boldHeading1,
                            makeNewLineAfterCustomized: true)
                .font(Fonts.muliHeading3)
                .foregroundColor(.aircastingGray)
        }
    }
    
    var micLabels: some View {
        VStack(alignment: .leading, spacing: 6) {
            StringCustomizer.customizeString(Strings.SelectDeviceView.micLabel_1,
                            using: [Strings.SelectDeviceView.phoneMicrophone],
                            fontWeight: .bold,
                            color: .accentColor,
                            font: Fonts.boldHeading1,
                            makeNewLineAfterCustomized: true)
                .font(Fonts.muliHeading3)
                .foregroundColor(.aircastingGray)
        }
    }
}
