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
    @State private var selection: CBPeripheral? = nil
    @State var observedObject: NSKeyValueObservation?
    
    var body: some View {
        VStack(spacing: 30) {
            ProgressView(value: 0.375)
            titileLabel
            
            LazyVStack(alignment: .leading, spacing: 25) {
                
                HStack(spacing: 8) {
                    Text("AirBeams")
                    if bluetoothManager.isScanning {
                        loader
                    } else {
                        loader.hidden()
                    }
            
                }
                displayDeviceButton(devices: bluetoothManager.airbeams)

                HStack(spacing: 8) {
                    Text("Other devices")
                    if bluetoothManager.isScanning {
                        loader
                    } else {
                        loader.hidden()
                    }
                }
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
        .onAppear(perform: {
            isScanningFinished()
        })
    }
    
    func isScanningFinished() {
        observedObject = bluetoothManager.observe(\BluetoothManager.isScanning) { BluetoothManager, change in
//            BluetoothManager.isScanning
        }
    }
    
    func displayDeviceButton(devices: [CBPeripheral]) -> some View {
        ForEach(devices, id: \.self) { (availableDevice) in
            Button(action: {
                selection = availableDevice
            }) {
                HStack(spacing: 20) {
                    CheckBox(isSelected: selection == availableDevice)
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
    
    var loader: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
    }
    
    var connectButton: some View {
        var destination: AnyView

        if let selection = selection {
            destination = AnyView(ConnectingABView(bluetoothManager: bluetoothManager,
                                               selecedPeripheral: selection))
        } else {
            destination = AnyView(EmptyView())
        }
        
        return NavigationLink(destination: destination) {
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
