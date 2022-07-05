// Created by Lunar on 16/11/2021.
//

import SwiftUI

struct SDSyncRootView: View {
    @StateObject private var viewModel: SDSyncRootViewModel = .init()
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            ProgressView(value: 0.142)
            Spacer()
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom), content: {
                syncImage
                loader
                    .padding()
                    .padding(.vertical)
            })
            Spacer()
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            Spacer()
        }
        .padding()
        .background(navigationLink)
        .onAppear() {
            finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = false
            viewModel.executeBackendSync()
        }
    }
}

private extension SDSyncRootView {
    var syncImage: some View {
        Image("airbeam")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(Strings.SDSyncRootView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.SDSyncRootView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var loader: some View {
        ZStack {
            Color.accentColor
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                .scaleEffect(2)
        }
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
