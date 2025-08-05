// Created by Lunar on 08/12/2021.
//

import AirCastingStyling
import SwiftUI

struct UnplugABView: View {
    @StateObject private var viewModel: UnplugABViewModel
    @Binding private var creatingSessionFlowContinues: Bool
    
    init(isSDClearProcess: Bool, creatingSessionFlowContinues: Binding<Bool>) {
        self._creatingSessionFlowContinues = .init(projectedValue: creatingSessionFlowContinues)
        self._viewModel = .init(wrappedValue: .init(isSDClearProcess: isSDClearProcess))
    }
    
    var body: some View {
        GeometryReader { reader in
            ProgressFlowAB(progress: 0.426, airbeamImageAsset: "airbeam-unplugged", title: Strings.UnplugAirbeamView.title, message: Strings.UnplugAirbeamView.message, continueButtonOnClick: viewModel.continueButtonTapped)
            .background(navigationLink)
        }
    }
}

extension UnplugABView {
    var navigationLink: some View {
        NavigationLink(
            destination: SDRestartABView(isSDClearProcess: viewModel.isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: .init(get: { viewModel.presentNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }
}
