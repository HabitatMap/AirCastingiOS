// Created by Lunar on 16/11/2021.
//

import SwiftUI

struct SDSyncRootView: View {
    @StateObject private var viewModel: SDSyncRootViewModel = .init()
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        GeometryReader { reader in
            ProgressFlowAB(progress: 0.142, abImage: ABCircleAndLoader(), title: Strings.SDSyncRootView.title, message: Strings.SDSyncRootView.message)
            .background(navigationLink)
            .onAppear() {
                finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = false
                viewModel.executeBackendSync()
            }
        }
    }
}

private extension SDSyncRootView {
    var navigationLink: some View {
        NavigationLink(
            destination: BackendSyncCompletedView(viewModel: BackendSyncCompletedViewModelDefault(),
                                                  creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: .init(get: { viewModel.backendSyncCompleted }, set: { _ in }),
            label: {
                EmptyView()
            })
    }
}
