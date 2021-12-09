//
//  TurnOnBluetoothView.swift
//  AirCasting
//
//  Created by Lunar on 03/02/2021.
//

import AirCastingStyling
import CoreBluetooth
import SwiftUI

struct TurnOnBluetoothView: View {
    @State private var isPowerABLinkActive = false
    @State private var presentRestartScreen = false
    @EnvironmentObject var settingsRedirection: DefaultSettingsRedirection
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var creatingSessionFlowContinues: Bool
    @Binding var sdSyncContinues: Bool
    var isSDClearProcess: Bool = false
    
    let urlProvider: BaseURLProvider
    
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.125)
            Image("1-bluetooth")
                .resizable()
                .scaledToFit()
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
                destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider),
                isActive: $isPowerABLinkActive,
                label: {
                    EmptyView()
                }
            )
           NavigationLink(
            destination: SDRestartABView(viewModel: SDRestartABViewModelDefault(urlProvider: urlProvider, isSDClearProcess: isSDClearProcess), creatingSessionFlowContinues: $creatingSessionFlowContinues),
                isActive: $presentRestartScreen,
                label: {
                    EmptyView()
                })
            }
        )
        .onAppear(perform: {
            if CBCentralManager.authorization != .allowedAlways {
                _ = bluetoothManager.centralManager
            }
        })
        .padding()
    }
    
    var titleLabel: some View {
        Text(Strings.TurnOnBluetoothView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.TurnOnBluetoothView.messageText)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
    }
    
    var continueButton: some View {
        Button(action: {
            if CBCentralManager.authorization == .denied {
                settingsRedirection.goToAppsBluetoothAuthSettings()
            } else if bluetoothManager.centralManager.state != .poweredOn {
                settingsRedirection.goToBluetoothAuthSettings()
            } else {
                sdSyncContinues ? presentRestartScreen.toggle() : isPowerABLinkActive.toggle()
            }
        }, label: {
            Text(Strings.TurnOnBluetoothView.continueButton)
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(BlueButtonStyle())
    }
}

