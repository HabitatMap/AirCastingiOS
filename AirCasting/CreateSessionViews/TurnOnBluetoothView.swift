//
//  TurnOnBluetoothView.swift
//  AirCasting
//
//  Created by Lunar on 03/02/2021.
//

import AirCastingStyling
import CoreBluetooth
import SwiftUI
import Resolver

struct TurnOnBluetoothView: View {
    @State private var isPowerABLinkActive = false
    @State private var presentRestartScreen = false
    @State private var presentUnplugScreen = false
    @Injected private var settingsRedirection: SettingsRedirection
    @Injected private var bluetoothManager: NewBluetoothManager
    @Binding var creatingSessionFlowContinues: Bool
    @Binding var sdSyncContinues: Bool
    var isSDClearProcess: Bool = false

    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: sdSyncContinues ? 0.355 : 0.125)
            Image("1-bluetooth")
                .resizable()
                .scaledToFit()
            Spacer()
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
                .buttonStyle(BlueButtonStyle())
        }
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
            if CBCentralManager.authorization != .allowedAlways {
                bluetoothManager.forceBluetoothPermissionPopup()
            }
        })
        .padding()
        .background(Color.aircastingBackground.ignoresSafeArea())
    }

    var titleLabel: some View {
        Text(Strings.TurnOnBluetoothView.title)
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.TurnOnBluetoothView.messageText)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
    }

    var continueButton: some View {
        Button(action: {
            if CBCentralManager.authorization == .denied {
                settingsRedirection.goToBluetoothSettings(type: .app)
            } else if bluetoothManager.centralManager.state != .poweredOn {
                settingsRedirection.goToBluetoothSettings(type: .global)
            } else {
                if isSDClearProcess {
                    presentRestartScreen.toggle()
                } else {
                    sdSyncContinues ? presentUnplugScreen.toggle() : isPowerABLinkActive.toggle()
                }
            }
        }, label: {
            Text(Strings.Commons.continue)
                .font(Fonts.muliBoldHeading1)
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(BlueButtonStyle())
    }
}
