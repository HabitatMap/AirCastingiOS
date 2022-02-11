// Created by Lunar on 27/07/2021.
//
import AirCastingStyling
import SwiftUI

struct TurnOnLocationView: View {
    @Binding var creatingSessionFlowContinues: Bool
    @StateObject var viewModel: TurnOnLocationViewModel
    
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
        }
        .padding()
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .background(
            Group {
                proceedToPowerABView
                proceedToBluetoothView
                proceedToSelectDeviceView
                proceedToRestartABView
            }
        )
        .onAppear {
            viewModel.requestLocationAuthorisation()
        }
        .onChange(of: viewModel.shouldShowAlert) { newValue in
            if newValue { viewModel.alert = InAppAlerts.locationAlert() }
        }
        .onAppCameToForeground {
            // The aim of this is to allow user to choose location option from native Apple location popup
            // It is the case when the user first nedded to turn on system location services at all.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.requestLocationAuthorisation()
            }
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
            viewModel.onButtonClick()
        }, label: {
            Text(Strings.Commons.continue)
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(BlueButtonStyle())
    }
    
    var proceedToPowerABView: some View {
        NavigationLink(
            destination: PowerABView(creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: $viewModel.isPowerABLinkActive,
            label: {
                EmptyView()
            })
    }
    var proceedToBluetoothView: some View {
        NavigationLink(
            destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                             sdSyncContinues: .constant(false),
                                             isSDClearProcess: viewModel.isSDClearProcess),
            isActive: $viewModel.isTurnBluetoothOnLinkActive,
            label: {
                EmptyView()
            })
    }
    var proceedToSelectDeviceView: some View {
        NavigationLink(
            destination: SelectDeviceView(creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                          sdSyncContinues: .constant(false)),
            isActive: $viewModel.isMobileLinkActive,
            label: {
                EmptyView()
            })
    }
    var proceedToRestartABView: some View {
        NavigationLink(
            destination: SDRestartABView(isSDClearProcess: viewModel.isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: $viewModel.restartABLink,
            label: {
                EmptyView()
            })
    }
}
