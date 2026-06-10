// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct SDRestartABView: View {
    @StateObject private var viewModel: SDRestartABViewModel
    @Binding private var creatingSessionFlowContinues: Bool
    
    init(isSDClearProcess: Bool, creatingSessionFlowContinues: Binding<Bool>) {
        self._creatingSessionFlowContinues = .init(projectedValue: creatingSessionFlowContinues)
        self._viewModel = .init(wrappedValue: .init(isSDClearProcess: isSDClearProcess))
    }
    
    var body: some View {
        GeometryReader { reader in
            ProgressFlowAB(progress: 0.568, airbeamImageAsset: "2-power", title: Strings.SDRestartABView.title, message: Strings.SDRestartABView.message, continueButtonOnClick: viewModel.continueSyncFlow)
            .background(selectDeviceLink)
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

extension SDRestartABView {
    var selectDeviceLink: some View {
        NavigationLink(
            destination: SelectPeripheralView(SDClearingRouteProcess: viewModel.isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues, syncMode: !viewModel.isSDClearProcess),
            isActive: $viewModel.presentNextScreen,
            label: {
                EmptyView()
            })
    }
}
