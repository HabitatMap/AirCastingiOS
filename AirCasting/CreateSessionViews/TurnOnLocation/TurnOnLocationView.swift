// Created by Lunar on 27/07/2021.
//

import AirCastingStyling
import SwiftUI

struct TurnOnLocationView: View {
    @State private var alert: AlertInfo?
    @State private var isPowerABLinkActive = false
    @State private var isTurnBluetoothOnLinkActive = false
    @State private var isMobileLinkActive = false
    @State private var restartABLink = false
    @Binding var creatingSessionFlowContinues: Bool
    var isSDClearProcess: Bool
    let viewModel: TurnOnLocationViewModel
    
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.125)
            Image("location-1")
                .resizable()
                .scaledToFit()
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
                .buttonStyle(BlueButtonStyle())
        }
        .alert(item: $alert, content: { $0.makeAlert() })
        .background(
            Group {
                proceedToPowerABView
                proceedToBluetoothView
                proceedToSelectDeviceView
                proceedToRestartABView
            }
        )
        .padding()
        .onAppear {
            viewModel.requestLocationAuthorisation()
            if viewModel.shouldShowAlert {
                alert = InAppAlerts.locationAlert()
            }
        }
        .onChange(of: viewModel.shouldShowAlert) { newValue in
            if newValue { alert = InAppAlerts.locationAlert() }
        }
    }
    
    var titleLabel: some View {
        Text(Strings.TurnOnLocationView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.TurnOnLocationView.messageText)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
    }
    
    var continueButton: some View {
        Button(action: {
            if viewModel.isMobileSession {
                isMobileLinkActive = true
            } else {
                if viewModel.checkIfBluetoothDenied() {
                    isTurnBluetoothOnLinkActive = true
                } else {
                    isSDClearProcess ? restartABLink.toggle() : isPowerABLinkActive.toggle()
                }
            }
        }, label: {
            Text(Strings.TurnOnLocationView.continueButton)
        })
        .disabled(viewModel.disableButton)
            .frame(maxWidth: .infinity)
            .buttonStyle(BlueButtonStyle())
    }
    
    var proceedToPowerABView: some View {
        NavigationLink(
            destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: viewModel.passURLProvider),
            isActive: $isPowerABLinkActive,
            label: {
                EmptyView()
            })
    }
    var proceedToBluetoothView: some View {
        NavigationLink(
            destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sdSyncContinues: .constant(false), isSDClearProcess: isSDClearProcess, urlProvider: viewModel.passURLProvider),
            isActive: $isTurnBluetoothOnLinkActive,
            label: {
                EmptyView()
            })
    }
    var proceedToSelectDeviceView: some View {
        NavigationLink(
            destination: SelectDeviceView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sdSyncContinues: .constant(false), urlProvider: viewModel.passURLProvider),
            isActive: $isMobileLinkActive,
            label: {
                EmptyView()
            })
    }
    var proceedToRestartABView: some View {
        NavigationLink(
            destination: SDRestartABView(viewModel: SDRestartABViewModelDefault(urlProvider: viewModel.passURLProvider, isSDClearProcess: isSDClearProcess), creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: $restartABLink,
            label: {
                EmptyView()
            })
    }
}
