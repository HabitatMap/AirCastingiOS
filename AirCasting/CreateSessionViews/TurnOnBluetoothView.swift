//
//  TurnOnBluetoothView.swift
//  AirCasting
//
//  Created by Lunar on 03/02/2021.
//

import SwiftUI
import CoreBluetooth

struct TurnOnBluetoothView: View {
    
    @State private var isPowerABLinkActive = false
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.125)
            Image("1-bluetooth")
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
                .buttonStyle(BlueButtonStyle())
        }
        .padding()
    }
    
    var titleLabel: some View {
        Text("Turn on Bluetooth")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("Turn on Bluetooth to enable your phone to connect to the AirBeam")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
    }
    
    var continueButton: some View {
        Button(action: {
            if CBCentralManager.authorization != .allowedAlways {
                goToBluetoothAuthSettings()
            } else {
                if bluetoothManager.centralManager.state != .poweredOn {
                    goToBluetoothSettings()
                } else {
                    isPowerABLinkActive = true
                }
            }
        }, label: {
            Text("Continue")
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(BlueButtonStyle())
        .background(
            NavigationLink(
                destination: PowerABView(),
                isActive: $isPowerABLinkActive,
                label: {
                    EmptyView()
                })
        )}
    
    func goToBluetoothSettings() {
        if let url = URL(string: "App-prefs:root=Bluetooth") {
            let app = UIApplication.shared
            if app.canOpenURL(url) {
                app.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    func goToBluetoothAuthSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            let app = UIApplication.shared
            if app.canOpenURL(url) {
                app.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

struct TurnOnBluetoothView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TurnOnBluetoothView()
        }
    }
}
