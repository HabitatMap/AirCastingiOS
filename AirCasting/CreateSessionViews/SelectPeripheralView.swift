//
//  SelectPeripheralView.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import AirCastingStyling
import CoreBluetooth
import SwiftUI
import Resolver

struct SelectPeripheralView: View {
    @State private var selection: CBPeripheral? = nil
    var SDClearingRouteProcess: Bool
    @InjectedObject private var bluetoothManager: BluetoothManager
    @EnvironmentObject var sessionContext: CreateSessionContext
    @Injected private var connectionController: AirBeamConnectionController
    @Binding var creatingSessionFlowContinues: Bool
    var syncMode: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                ProgressView(value: syncMode ? 0.710 : 0.375)
                titleLabel
                ScrollView {
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
                    Spacer()
                }
                .listStyle(PlainListStyle())
                .font(Fonts.moderateRegularHeading1)
                .foregroundColor(.aircastingDarkGray)
                if !bluetoothManager.isScanning {
                    refreshButton
                        .font(Fonts.moderateRegularHeading3)
                        .frame(alignment: .trailing)
                }
                connectButton.disabled(selection == nil)
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
            .background(Color.aircastingBackgroundWhite.ignoresSafeArea())
            .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
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
        var title: Text
        if syncMode == true {
            title = Text(Strings.SelectPeripheralView.titleSyncLabel)
        } else if SDClearingRouteProcess {
            title = Text(Strings.SelectPeripheralView.titleSDClearLabel)
        }  else {
            title = Text(Strings.SelectPeripheralView.titleLabel)
        }
        return title
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
            .multilineTextAlignment(.leading)
            .lineSpacing(10.0)
    }
    
    func showDevice(name: String) -> some View {
        Text(name)
            .font(Fonts.muliMediumHeading1)
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
            if syncMode == true {
                let viewModel =
                SDSyncViewModelDefault(sessionContext: sessionContext,
                                       peripheral: selection)
                destination = AnyView(SyncingABView(viewModel: viewModel, creatingSessionFlowContinues: $creatingSessionFlowContinues))
            } else if SDClearingRouteProcess {
                let viewModel = ClearingSDCardViewModelDefault(isSDClearProcess: SDClearingRouteProcess, peripheral: selection)
                destination = AnyView(ClearingSDCardView(viewModel: viewModel, creatingSessionFlowContinues: $creatingSessionFlowContinues))
            } else {
                let viewModel =
                AirbeamConnectionViewModelDefault(sessionContext: sessionContext,
                                                  peripheral: selection)
                destination = AnyView(ConnectingABView(viewModel: viewModel, creatingSessionFlowContinues: $creatingSessionFlowContinues))
            }
        } else {
            destination = AnyView(EmptyView())
        }
        return NavigationLink(destination: destination) {
            Text(Strings.SelectPeripheralView.connectText)
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
    }
}
