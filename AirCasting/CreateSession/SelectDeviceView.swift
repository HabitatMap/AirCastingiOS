//
//  SelectDeviceView.swift
//  AirCasting
//
//  Created by Lunar on 07/02/2021.
//

import SwiftUI

struct SelectDeviceView: View {
    
    @State private var selected = 0
    @State private var isBluetoothLinkActive: Bool = false
    @State private var isMicLinkActive: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            ProgressView(value: 0.125)
            titleLabel
            bluetoothButton
            micButton
            Spacer()
            chooseButton
            
        }
        .padding()
    }
    
    var titleLabel: some View {
        Text("What device are you using to record this session?")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    
    var bluetoothButton: some View {
        Button(action: {
            selected = 1
        }, label: {
            bluetoothLabels
        })
        .buttonStyle(WhiteButtonStyle(isSelected: selected == 1))
    }
    
    var micButton: some View {
        Button(action: {
            selected = 2
        }, label: {
            micLabels
        })
        .buttonStyle(WhiteButtonStyle(isSelected: selected == 2))
    }
    
    var bluetoothLabels: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bluetooth device")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("for example AirBeam")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var micLabels: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Phone microphone")
                .font(Font.muli(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            Text("to measure sound level")
                .font(Font.muli(size: 14, weight: .regular))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var chooseButton: some View {
        Button(action: {
            if selected == 1 {
                isBluetoothLinkActive = true
            } else if selected == 2 {
                isMicLinkActive = true
            }
        }, label: {
            Text("Choose")
        })
        .buttonStyle(BlueButtonStyle())
        .background( Group {
            NavigationLink(
                destination: TurnOnBluetoothView(),
                isActive: $isBluetoothLinkActive,
                label: {
                    EmptyView()
                })
            NavigationLink(
                // TO DO: change destination
                destination: PowerABView(),
                isActive: $isMicLinkActive,
                label: {
                    EmptyView()
                })
        })
    }
}

struct SelectDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        SelectDeviceView()
    }
}
