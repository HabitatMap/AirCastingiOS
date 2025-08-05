// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct BackendSyncCompletedView<VM: BackendSyncCompletedViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        GeometryReader { reader in
            ProgressFlowAB(progress: 0.284, airbeamImageAsset: "4-connected", title: Strings.SDSyncSuccessView.title, message: Strings.SDSyncSuccessView.message, continueButtonOnClick: viewModel.continueButtonTapped)
            .background(Group { restartNavigationLink; BTNavigationLink; locationNavigationLink })
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
            destination: UnplugABView(isSDClearProcess: false, creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: .init(get: { viewModel.presentRestartNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
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
