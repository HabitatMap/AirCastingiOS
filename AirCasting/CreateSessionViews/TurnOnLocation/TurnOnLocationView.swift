// Created by Lunar on 27/07/2021.
//

import AirCastingStyling
import CoreBluetooth
import SwiftUI

struct TurnOnLocationView: View {
    @State private var isPowerABLinkActive = false
    @State private var showAlert = false
    @State private var isTurnBluetoothOnLinkActive = false
    @State private var isMobileLinkActive = false
    @Binding var creatingSessionFlowContinues: Bool
    
    @EnvironmentObject var settingsRedirection: DefaultSettingsRedirection
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject private var locationTracker: LocationTracker
    @StateObject var sessionContext: CreateSessionContext
    let urlProvider: BaseURLProvider
    
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.125)
            Image("location-1")
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
                .buttonStyle(BlueButtonStyle())
        }
        .alert(isPresented: $showAlert) {
            Alert.locationAlert
        }
        .background(
            Group {
                proceedToPowerABView
                proceedToBluetoothView
                proceedToSelectDeviceView
            }
        )
        .padding()
        .onAppear {
            locationTracker.requestAuthorisation()
            if locationTracker.locationGranted == .denied {
                showAlert = true
            }
        }
        .onChange(of: locationTracker.locationGranted) { newValue in
            showAlert = (newValue == .denied)
        }
    }
    
    var titleLabel: some View {
        Text(Strings.TurnOnLocationView.title)
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.TurnOnLocationView.messageText)
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
    }
    
    var continueButton: some View {
        Button(action: {
            if sessionContext.sessionType == .mobile {
                isMobileLinkActive = true
            } else {
                if CBCentralManager.authorization == .notDetermined {
                    isTurnBluetoothOnLinkActive = true
                } else {
                    isPowerABLinkActive = true
                }
            }
        }, label: {
            Text(Strings.TurnOnLocationView.continueButton)
        })
        .disabled(locationTracker.locationGranted != .granted)
            .frame(maxWidth: .infinity)
            .buttonStyle(BlueButtonStyle())
    }
    
    var proceedToPowerABView: some View {
        NavigationLink(
            destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider),
            isActive: $isPowerABLinkActive,
            label: {
                EmptyView()
            })
    }
    var proceedToBluetoothView: some View {
        NavigationLink(
            destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sessionContext: sessionContext, urlProvider: urlProvider),
            isActive: $isTurnBluetoothOnLinkActive,
            label: {
                EmptyView()
            })
    }
    var proceedToSelectDeviceView: some View {
        NavigationLink(
            destination: SelectDeviceView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider),
            isActive: $isMobileLinkActive,
            label: {
                EmptyView()
            })
    }
}

struct TurnOnLocationView_Previews: PreviewProvider {
    static var previews: some View {
        TurnOnLocationView(creatingSessionFlowContinues: .constant(true), sessionContext: CreateSessionContext(), urlProvider: DummyURLProvider())
    }
}
