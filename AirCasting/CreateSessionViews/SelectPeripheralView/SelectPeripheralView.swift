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
    @State private var selection: (any BluetoothDevice)? = nil
    var SDClearingRouteProcess: Bool
    @EnvironmentObject var sessionContext: CreateSessionContext
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
    
    func displayDeviceButton(devices: [any BluetoothDevice]) -> some View {
        ForEach(devices, id: \.uuid) { availableDevice in
            Button(action: {
                selection = availableDevice
                sessionContext.device = availableDevice
                // TODO: AB shouldn't be hardcoded
                sessionContext.deviceType = .AIRBEAM
            }) {
                HStack(spacing: 20) {
                    CheckBox(isSelected: selection?.uuid == availableDevice.uuid)
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
                // V1 inserts an "Unplug your AirBeam" prompt between device
                // selection and the sync screen — the firmware can only
                // enter SD download mode while the device is on USB power,
                // and the user needs to know to disconnect the cable first.
                // V2 has no such requirement, so it goes straight to sync.
                if selection.firmwareVersion == .v1 {
                    destination = AnyView(PreSyncUnplugABView(sessionContext: sessionContext,
                                                              device: selection,
                                                              creatingSessionFlowContinues: $creatingSessionFlowContinues))
                } else {
                    let viewModel =
                    SDSyncViewModelDefault(sessionContext: sessionContext,
                                           device: selection)
                    destination = AnyView(SyncingABView(viewModel: viewModel, creatingSessionFlowContinues: $creatingSessionFlowContinues))
                }
            } else if SDClearingRouteProcess {
                let viewModel = ClearingSDCardViewModelDefault(isSDClearProcess: SDClearingRouteProcess, device: selection)
                destination = AnyView(ClearingSDCardView(viewModel: viewModel, creatingSessionFlowContinues: $creatingSessionFlowContinues))
            } else {
                destination = AnyView(ConnectingABView(sessionContext: sessionContext,
                                                       device: selection, creatingSessionFlowContinues: $creatingSessionFlowContinues))
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

/// V1-only "Unplug your AirBeam" prompt inserted between device selection and
/// the sync screen. The firmware can only enter SD download mode while the
/// device is off USB power, so the user must physically unplug before we
/// kick off SyncingABView. V2 has no such requirement and skips this entirely.
private struct PreSyncUnplugABView: View {
    let sessionContext: CreateSessionContext
    let device: any BluetoothDevice
    @Binding var creatingSessionFlowContinues: Bool
    @State private var presentNextScreen: Bool = false

    var body: some View {
        ProgressFlowAB(progress: 0.78,
                       airbeamImageAsset: "airbeam-unplugged",
                       title: Strings.UnplugAirbeamView.title,
                       message: Strings.UnplugAirbeamView.message) {
            presentNextScreen = true
        }
        .background(
            NavigationLink(
                destination: SyncingABView(viewModel: SDSyncViewModelDefault(sessionContext: sessionContext,
                                                                              device: device),
                                            creatingSessionFlowContinues: $creatingSessionFlowContinues),
                isActive: $presentNextScreen,
                label: { EmptyView() }
            )
        )
    }
}
