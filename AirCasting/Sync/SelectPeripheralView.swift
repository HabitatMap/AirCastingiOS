//
//  SelectPeripheralView.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import SwiftUI

struct SelectPeripheralView: View {
    
    var bluetoothManager = BluetoothManager()
    let availableDevices: [String] = ["AirBeam 1 :1209483437",
                                      "AirBeeam 2 :475834593",
                                      "AirBeam 3 :45897028547",
                                      "iPhone 11"]
    
    
    var body: some View {
        VStack {
            titileLabel
            LazyVStack(alignment: .leading, spacing: 25) {
                Text("AirBeams")
                ForEach(availableDevices, id: \.self) { (availableDevice) in
                    HStack {
                        // TO DO: Add logic for selecting device.
                        CheckBox(isSelected: false)
                        showDevice(name: availableDevice)
                    }
                }
                Text("Other devices")
            }
            .font(Font.moderate(size: 18, weight: .regular))
            .foregroundColor(.aircastingDarkGray)
        }
        .padding()
    }
    
    var titileLabel: some View {
        Text("Choose the device you'd like to record with")
            .font(Font.moderate(size: 25, weight: .bold))
            .foregroundColor(.accentColor)
            .multilineTextAlignment(.leading)
            .lineSpacing(10.0)
    }
    
    func showDevice(name: String) -> some View {
            Text(name)
                .font(Font.muli(size: 16, weight: .medium))
                .foregroundColor(.aircastingGray)
    }
}

struct SelectPeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        SelectPeripheralView()
    }
}
