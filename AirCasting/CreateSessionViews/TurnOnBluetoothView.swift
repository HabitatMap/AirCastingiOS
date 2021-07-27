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
    @EnvironmentObject var settingsRedirection: DefaultSettingsRedirection
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var creatingSessionFlowContinues: Bool
    
    let urlProvider: BaseURLProvider
    
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
        .background(
            NavigationLink(
                destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider),
                isActive: $isPowerABLinkActive,
                label: {
                    EmptyView()
                }
            )
        )
        .padding()
    }
    
    var titleLabel: some View {
        Text(Strings.TurnOnBluetoothView.title)
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.TurnOnBluetoothView.messageText)
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
    }
    
    var continueButton: some View {
        Button(action: {
            _ = CBCentralManager()
//            isPowerABLinkActive = true
//            if CBCentralManager.authorization != .allowedAlways {
//                settingsRedirection.goToBluetoothAuthSettings()
//            } else {
//                if bluetoothManager.centralManager.state != .poweredOn {
//                    settingsRedirection.goToBluetoothAuthSettings()
//                } else {
//                    isPowerABLinkActive = true
//                }
//            }
        }, label: {
            Text(Strings.TurnOnBluetoothView.continueButton)
        })
            .frame(maxWidth: .infinity)
            .buttonStyle(BlueButtonStyle())
    }
}

#if DEBUG
struct TurnOnBluetoothView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TurnOnBluetoothView(creatingSessionFlowContinues: .constant(true), urlProvider: DummyURLProvider())
        }
    }
}
#endif
