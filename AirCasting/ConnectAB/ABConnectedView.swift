//
//  AirbeamConnectedView.swift
//  AirCasting
//
//  Created by Lunar on 17/02/2021.
//

import SwiftUI

struct ABConnectedView: View {
    
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var context: AirbeamSetupContext

    var body: some View {
        let configurator = AirBeam3Configurator(peripheral: context.peripheral!)
        VStack(spacing: 40) {
            ProgressView(value: 0.625)
            Image("4-connected")
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            Button("Fixed Wifi") {
                let testFixedSession = Session(name: "FixedWifi")
                configurator.configure(session: testFixedSession,
                                       wifiSSID: "toya88804693",
                                       wifiPassword: "07078914")
            }
//            Button("Fixed Cellular") {
//
//            }
            continueButton
        }
        .padding()
    }
    var titleLabel: some View {
        Text("AirBeam connected")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("Your AirBeam is connected to your phone and ready to take some measurements.")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
    }
    var continueButton: some View {
        Button(action: {
            print("Someting will happen, soon.")
        },
               label: {
            Text("Continue")
        })
        .buttonStyle(BlueButtonStyle())
    }
}

struct AirbeamConnectedView_Previews: PreviewProvider {
    static var previews: some View {
        ABConnectedView()
    }
}
