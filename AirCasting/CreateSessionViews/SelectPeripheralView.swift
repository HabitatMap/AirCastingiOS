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
    @State private var selection: CBPeripheral? = nil
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var sessionContext: CreateSessionContext
    @EnvironmentObject var connectionController: DefaultAirBeamConnectionController
    @Binding var creatingSessionFlowContinues: Bool
    let urlProvider: BaseURLProvider
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    ProgressView(value: 0.375)
                    titleLabel
                    
                    LazyVStack(alignment: .leading, spacing: 25) {
                        HStack(spacing: 8) {
                            Text(Strings.SelectPeripheralView.airBeamsText)
                            if bluetoothManager.isScanning {
                                loader
                            }
                        }
                        displayDeviceButton(devices: bluetoothManager.airbeams)
                        
                        HStack(spacing: 8) {
                            Text(Strings.SelectPeripheralView.otherText)
                            if bluetoothManager.isScanning {
                                loader
                            }
                        }
                        displayDeviceButton(devices: bluetoothManager.otherDevices)
                    }
                    .listStyle(PlainListStyle())
                    .listItemTint(Color.red)
                    .font(Fonts.regularHeading1)
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
                }
                .onAppear {
                    if CBCentralManager.authorization == .allowedAlways {
                        // it triggers the bluetooth searching on the appearing time
                        _ = bluetoothManager.centralManager
                        bluetoothManager.startScanning()
                    }
                }
                .onDisappear {
                    bluetoothManager.centralManager.stopScan()
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
        }
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
    
    var titleLabel: some View {
        Text(Strings.SelectPeripheralView.titleLabel)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
            .multilineTextAlignment(.leading)
            .lineSpacing(10.0)
    }
    
    func showDevice(name: String) -> some View {
        Text(name)
            .font(Fonts.mediumHeading1)
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
            Text(Strings.SelectPeripheralView.refreshButton)
        })
    }
    
    var connectButton: some View {
        var destination: AnyView
        if let selection = selection {
            let viewModel =
            AirbeamConnectionViewModelDefault(airBeamConnectionController: connectionController,
                                              userAuthenticationSession: userAuthenticationSession, sessionContext: sessionContext,
                                              peripheral: selection)
            destination = AnyView(ConnectingABView(viewModel: viewModel, baseURL: urlProvider, creatingSessionFlowContinues: $creatingSessionFlowContinues))
        } else {
            destination = AnyView(EmptyView())
        }
        return NavigationLink(destination: destination) {
            Text(Strings.SelectPeripheralView.connectText)
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
