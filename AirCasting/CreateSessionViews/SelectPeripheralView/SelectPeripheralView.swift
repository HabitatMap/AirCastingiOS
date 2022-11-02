//
//  SelectPeripheralView.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import AirCastingStyling
import SwiftUI
import Resolver

struct SelectPeripheralView: View {
    @StateObject var viewModel = SelectPeripheralViewModel()
    @State private var selection: NewBluetoothManager.BluetoothDevice? = nil
    var SDClearingRouteProcess: Bool
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
                            if viewModel.isScanning {
                                loader
                            }
                        }
                        displayDeviceButton(devices: viewModel.airbeams)
                        
                        HStack(spacing: 8) {
                            Text(Strings.SelectPeripheralView.otherText)
                            if viewModel.isScanning {
                                loader
                            }
                        }
                        displayDeviceButton(devices: viewModel.otherDevices)
                    }
                    Spacer()
                }
                .listStyle(PlainListStyle())
                .font(Fonts.moderateRegularHeading1)
                .foregroundColor(.aircastingDarkGray)
                if !viewModel.isScanning {
                    refreshButton
                        .font(Fonts.moderateRegularHeading3)
                        .frame(alignment: .trailing)
                }
                connectButton.disabled(selection == nil)
            }
            .onAppear {
                viewModel.viewAppeared()
            }
            .onDisappear {
                viewModel.viewDisappeared()
            }
            .padding()
            .background(Color.aircastingBackground.ignoresSafeArea())
            .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
        }
    }
    
    func displayDeviceButton(devices: [NewBluetoothManager.BluetoothDevice]) -> some View {
        ForEach(devices, id: \.id) { availableDevice in
            Button(action: {
                selection = availableDevice
                sessionContext.peripheral = availableDevice.peripheral //CHANGE WHEN NEW LOGIC FOR RECORDING SESSION WILL BE IMPLEMENTED
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
            viewModel.refreshButtonTapped()
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
                                       peripheral: selection.peripheral)
                destination = AnyView(SyncingABView(viewModel: viewModel, creatingSessionFlowContinues: $creatingSessionFlowContinues))
            } else if SDClearingRouteProcess {
                let viewModel = ClearingSDCardViewModelDefault(isSDClearProcess: SDClearingRouteProcess, peripheral: selection.peripheral)
                destination = AnyView(ClearingSDCardView(viewModel: viewModel, creatingSessionFlowContinues: $creatingSessionFlowContinues))
            } else {
                destination = AnyView(ConnectingABView(sessionContext: sessionContext,
                                                       peripheral: selection.peripheral, creatingSessionFlowContinues: $creatingSessionFlowContinues))
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
