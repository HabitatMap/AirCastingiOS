//
//  TurnOnBluetoothView.swift
//  AirCasting
//
//  Created by Lunar on 03/02/2021.
//

import SwiftUI

struct TurnOnBluetoothView: View {
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.125)
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
            .lineSpacing(/*@START_MENU_TOKEN@*/10.0/*@END_MENU_TOKEN@*/)

    }
    var continueButton: some View {
        // To do: start scanning when clicked continue
//                        bluetoothManager.startScanning()
        NavigationLink(destination: PowerABView()) {
            Text("Continue")
                .frame(maxWidth: .infinity)
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
