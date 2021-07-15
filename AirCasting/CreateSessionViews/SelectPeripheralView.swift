//
//  SelectPeripheralView.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import AirCastingStyling
import CoreBluetooth
import SwiftUI

struct SelectPeripheralView: View {
    @State private var showBluetoothAlert = false
    @State private var selection: CBPeripheral? = nil
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var sessionContext: CreateSessionContext
    
    @Binding var creatingSessionFlowContinues: Bool
    
    let urlProvider: BaseURLProvider
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    ProgressView(value: 0.375)
                    titileLabel
                    
                    LazyVStack(alignment: .leading, spacing: 25) {
                        HStack(spacing: 8) {
                            Text("AirBeams")
                            if bluetoothManager.isScanning {
                                loader
                            }
                        }
                        displayDeviceButton(devices: bluetoothManager.airbeams)
                        
                        HStack(spacing: 8) {
                            Text("Other devices")
                            if bluetoothManager.isScanning {
                                loader
                            }
                        }
                        displayDeviceButton(devices: bluetoothManager.otherDevices)
                    }
                    .listStyle(PlainListStyle())
                    .listItemTint(Color.red)
                    .font(Font.moderate(size: 18, weight: .regular))
                    .foregroundColor(.aircastingDarkGray)
                    
                    Spacer()
                    
                    if !bluetoothManager.isScanning {
                        refreshButton
                            .frame(alignment: .trailing)
                    }
                    
                    if selection != nil {
                        connectButton.disabled(false)
                    } else {
                        connectButton.disabled(true)
                    }
                }.alert(isPresented: $showBluetoothAlert, content: {
                    Alert(title: Text("Connection error"), message: Text("Please, choose a different device or try again"), dismissButton: .default(Text("Got it!")))
                })
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
        }.onChange(of: bluetoothManager.isConnected, perform: { value in
            showBluetoothAlert = !value
        })
            .onAppear(perform: {
                bluetoothManager.isConnected = true
            })
    }
    
    func displayDeviceButton(devices: [CBPeripheral]) -> some View {
        ForEach(devices, id: \.self) { availableDevice in
            Button(action: {
                selection = availableDevice
                
                sessionContext.peripheral = availableDevice
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
    
    var refreshButton: some View {
        Button(action: {
            bluetoothManager.startScanning()
        }, label: {
            Text("Don't see a device? Refresh scanning.")
        })
    }
    
    var connectButton: some View {
        var destination: AnyView
        if let selection = selection {
            destination = AnyView(ConnectingABView(bluetoothManager: bluetoothManager,
                                                   selectedPeripheral: selection, baseURL: urlProvider,
                                                   creatingSessionFlowContinues: $creatingSessionFlowContinues))
        } else {
            destination = AnyView(EmptyView())
        }
        
        return NavigationLink(destination: destination) {
            Text("Connect")
        }
        .buttonStyle(BlueButtonStyle())
    }
}

#if DEBUG
struct SelectPeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        SelectPeripheralView(creatingSessionFlowContinues: .constant(true), urlProvider: DummyURLProvider())
    }
}
#endif
