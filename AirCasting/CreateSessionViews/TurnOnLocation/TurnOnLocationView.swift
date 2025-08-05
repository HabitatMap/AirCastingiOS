// Created by Lunar on 27/07/2021.
//
import AirCastingStyling
import SwiftUI

struct TurnOnLocationView: View {
    @Binding var creatingSessionFlowContinues: Bool
    @StateObject var viewModel: TurnOnLocationViewModel
    
    var body: some View {
        ProgressFlowAB(progress: 0.125, airbeamImageAsset: "location-1", title: Strings.TurnOnLocationView.title, message: Strings.TurnOnLocationView.messageText, continueButtonOnClick: viewModel.onButtonClick)
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .background(
            Group {
                proceedToPowerABView
                proceedToBluetoothView
                proceedToSelectDeviceView
                proceedToRestartABView
                proceedToUnplugABView
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
                                             sdSyncContinues: .constant(viewModel.isSDSyncProcess),
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
            isActive: $viewModel.isProceedToSelectDeviceTypeLinkActive,
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
    var proceedToUnplugABView: some View {
        NavigationLink(
            destination: UnplugABView(isSDClearProcess: viewModel.isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: $viewModel.unplugABLink,
            label: {
                EmptyView()
            })
    }
}
