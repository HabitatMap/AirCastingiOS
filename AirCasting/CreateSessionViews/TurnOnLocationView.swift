// Created by Lunar on 27/07/2021.
//

import SwiftUI
import AirCastingStyling
import CoreBluetooth

struct TurnOnLocationView: View {
    @State private var isPowerABLinkActive = false
    @State private var showAlert = false
    @State private var isTurnBluetoothOnLinkActive = false
    @State private var isMobileLinkActive = false
    @EnvironmentObject var settingsRedirection: DefaultSettingsRedirection
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @StateObject private var locationTracker = LocationTracker()
    @StateObject var sessionContext: CreateSessionContext
    private var continueButtonEnabled: Bool {
        locationTracker.locationGranted == .granted
    }
    
    let urlProvider: BaseURLProvider
    
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.125)
            Image("1-bluetooth")
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
                .buttonStyle(BlueButtonStyle())
        }
        .background(
            Group {
                NavigationLink(
                    destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider),
                    isActive: $isPowerABLinkActive,
                    label: {
                        EmptyView()
                    })
                NavigationLink(
                    destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sessionContext: sessionContext, urlProvider: urlProvider),
                    isActive: $isTurnBluetoothOnLinkActive,
                    label: {
                        EmptyView()
                    })
                NavigationLink(
                    destination: SelectDeviceView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider),
                    isActive: $isMobileLinkActive,
                    label: {
                        EmptyView()
                    })
            }
        )
        .padding()
        .onAppear {
            locationTracker.requestAuthorisation()
        }
        .onChange(of: locationTracker.locationGranted) { newValue in
            showAlert = (newValue == .denied)
        }
    }
    
    var titleLabel: some View {
        Text("LOCATION")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.TurnOnBluetoothView.messageText)
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
    }
    
    var continueButton: some View {
        Button(action: {
            if locationTracker.locationGranted == .denied {
                settingsRedirection.goToLocationAuthSettings()
            } else {
                if sessionContext.sessionType == .mobile {
                    isMobileLinkActive = true
                } else {
                    isTurnBluetoothOnLinkActive = true
                }
            }
        }, label: {
            Text(Strings.TurnOnBluetoothView.continueButton)
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(BlueButtonStyle())
    }
}

struct TurnOnLocationView_Previews: PreviewProvider {
    static var previews: some View {
        TurnOnLocationView(creatingSessionFlowContinues: .constant(true), sessionContext: CreateSessionContext(), urlProvider: DummyURLProvider())
    }
}
