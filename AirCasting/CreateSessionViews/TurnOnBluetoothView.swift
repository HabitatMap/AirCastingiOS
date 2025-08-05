//
//  TurnOnBluetoothView.swift
//  AirCasting
//
//  Created by Lunar on 03/02/2021.
//

import AirCastingStyling
import SwiftUI
import Resolver

struct TurnOnBluetoothView: View {
    @State private var isPowerABLinkActive = false
    @State private var presentRestartScreen = false
    @State private var presentUnplugScreen = false
    @Injected private var settingsRedirection: SettingsRedirection
    @Injected private var bluetoothManager: BluetoothStateHandler
    @Binding var creatingSessionFlowContinues: Bool
    @Binding var sdSyncContinues: Bool
    var isSDClearProcess: Bool = false

    var body: some View {
        ProgressFlowAB(progress: sdSyncContinues ? 0.355 : 0.125, airbeamImageAsset: "1-bluetooth", title: Strings.TurnOnBluetoothView.title, message: Strings.TurnOnBluetoothView.messageText, continueButtonOnClick: {
            if bluetoothManager.authorizationState == .denied {
                settingsRedirection.goToBluetoothSettings(type: .app)
            } else if bluetoothManager.deviceState != .poweredOn {
                settingsRedirection.goToBluetoothSettings(type: .global)
            } else {
                if isSDClearProcess {
                    presentRestartScreen.toggle()
                } else {
                    sdSyncContinues ? presentUnplugScreen.toggle() : isPowerABLinkActive.toggle()
                }
            }
        })
        .background(
            Group {
                NavigationLink(
                    destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues),
                    isActive: $isPowerABLinkActive,
                    label: {
                        EmptyView()
                    }
                )
                NavigationLink(
                    destination: UnplugABView(isSDClearProcess: isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues),
                    isActive: $presentUnplugScreen,
                    label: {
                        EmptyView()
                    }
                )
                NavigationLink(
                    destination: SDRestartABView(isSDClearProcess: isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues),
                    isActive: $presentRestartScreen,
                    label: {
                        EmptyView()
                    })
            }
        )
        .onAppear(perform: {
            bluetoothManager.forceBluetoothPermissionPopup()
        })
    }
}
