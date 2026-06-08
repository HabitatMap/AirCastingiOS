// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct BackendSyncCompletedView<VM: BackendSyncCompletedViewModel>: View {
    @StateObject var viewModel: VM
    @EnvironmentObject private var standaloneSessionToSyncAndFinish: StandaloneSessionToSyncAndFinish
    @Binding var creatingSessionFlowContinues: Bool

    var body: some View {
        GeometryReader { reader in
            ProgressFlowAB(progress: 0.284, airbeamImageAsset: "4-connected", title: Strings.SDSyncSuccessView.title, message: Strings.SDSyncSuccessView.message, continueButtonOnClick: viewModel.continueButtonTapped)
            .background(Group { restartNavigationLink; BTNavigationLink; locationNavigationLink; selectPeripheralNavigationLink })
        }
    }
}

private extension BackendSyncCompletedView {
    var locationNavigationLink: some View {
        NavigationLink(
            destination: TurnOnLocationView(creatingSessionFlowContinues: $creatingSessionFlowContinues, viewModel: TurnOnLocationViewModel(process: .sdSync)),
            isActive: .init(get: { viewModel.presentLocationNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }

    var restartNavigationLink: some View {
        NavigationLink(
            destination: destinationForRestart(),
            isActive: .init(get: { viewModel.presentRestartNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }

    /// V2 has no SD card and no physical unplug step — go straight to peripheral
    /// selection. V1 keeps the existing "Unplug AirBeam" → "Power on AirBeam"
    /// pre-sync screens.
    @ViewBuilder
    func destinationForRestart() -> some View {
        if standaloneSessionToSyncAndFinish.isV2 {
            // V2 — no SD card, no physical unplug. Skip straight to peripheral
            // selection so the BLE manual-sync flow (StartBleSync 0x16) can run.
            SelectPeripheralView(SDClearingRouteProcess: false,
                                 creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                 syncMode: true)
        } else {
            // V1 reorder (Android commit `dcef0b695`): the "Unplug AirBeam"
            // screen has moved to AFTER the post-sync success screen
            // (SDSyncCompleteView). Go straight to the "Power on AirBeam"
            // restart screen here so the user picks the SD-card-having device
            // immediately.
            SDRestartABView(isSDClearProcess: false,
                            creatingSessionFlowContinues: $creatingSessionFlowContinues)
        }
    }

    /// Kept for legacy callers that wanted to inject a different downstream view.
    /// Currently unused — `destinationForRestart` covers both V1 + V2.
    var selectPeripheralNavigationLink: some View {
        EmptyView()
    }
    
    var BTNavigationLink: some View {
        NavigationLink(
            destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sdSyncContinues: .constant(true)),
            isActive: .init(get: { viewModel.presentBTNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }
}
