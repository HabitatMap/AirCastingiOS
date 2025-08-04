// Created by Lunar on 16/11/2021.
//

import SwiftUI

struct SDSyncRootView: View {
    @StateObject private var viewModel: SDSyncRootViewModel = .init()
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 40) {
                ProgressView(value: 0.142)
                Spacer()
                ABCircleAndLoader()
                Spacer()
                VStack(alignment: .leading, spacing: 15) {
                    titleLabel
                    messageLabel
                }
                Spacer()
            }
            .padding()
            .background(navigationLink)
            .background(Color.aircastingBackground.ignoresSafeArea())
            .onAppear() {
                finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = false
                viewModel.executeBackendSync()
            }
        }
    }
}

private extension SDSyncRootView {
    var syncImage: some View {
        Image("airbeam")
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(Strings.SDSyncRootView.title)
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.SDSyncRootView.message)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
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
