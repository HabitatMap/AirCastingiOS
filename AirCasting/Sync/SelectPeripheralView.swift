//
//  SelectPeripheralView.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import SwiftUI
import CoreBluetooth

struct SelectPeripheralView: View {
    
    @ObservedObject var bluetoothManager = BluetoothManager()
    @State private var selection: String? = nil
    
    var body: some View {
        VStack(spacing: 30) {
            ProgressView(value: 0.375)
            titileLabel
            
            LazyVStack(alignment: .leading, spacing: 25) {
                Text("AirBeams")
                displayDeviceButton(devices: bluetoothManager.airbeams)

                Text("Other devices")
                displayDeviceButton(devices: bluetoothManager.otherDevices)
            }
            .listStyle(PlainListStyle())
            .listItemTint(Color.red)
            .font(Font.moderate(size: 18, weight: .regular))
            .foregroundColor(.aircastingDarkGray)
            Spacer()
            connectButton
        }
        .padding()
    }
    
    func displayDeviceButton(devices: [CBPeripheral]) -> some View {
        ForEach(devices, id: \.self) { (availableDevice) in
            Button(action: {
                selection = availableDevice.name
            }) {
                HStack {
                    CheckBox(isSelected: selection == availableDevice.name)
                    showDevice(name: availableDevice.name ?? "")
                }
            }
        }
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
    
    var connectButton: some View {
        NavigationLink(destination: ConnectingABView()) {
            Text("Connect")
        }
        .buttonStyle(BlueButtonStyle())
    }
}

struct SelectPeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        SelectPeripheralView()
    }
}
