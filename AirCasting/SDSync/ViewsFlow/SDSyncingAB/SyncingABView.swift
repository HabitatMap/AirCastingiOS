//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI

struct SyncingABView<VM: SDSyncViewModel>: View {
    @StateObject var viewModel: VM
    @State var progressTitle: String?
    @State var progressCount: String?
    @EnvironmentObject private var standaloneSessionToSyncAndFinish: StandaloneSessionToSyncAndFinish
    @Binding var creatingSessionFlowContinues: Bool

    var body: some View {
        let title = if viewModel.isDownloadingFinished {
            Strings.SyncingABView.finishingSyncTitle
        } else if let progressTitle {
            "Syncing \(progressTitle.lowercased()) \(progressCount ?? "")"
        } else {
            Strings.SyncingABView.startingSyncTitle
        }
        
        ProgressFlowAB(progress: 0.852, abImage: ABCircleAndLoader(), title: title, message: Strings.SyncingABView.message)
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .onChange(of: viewModel.shouldDismiss, perform: { $0 ? creatingSessionFlowContinues = false : nil })
        .background(navigationLink)
        .onReceive(viewModel.progress, perform: { newProgress in
            if let progress = newProgress {
                self.progressTitle = progress.title
                self.progressCount = "\(progress.current)/\(progress.total)"
            }
        })
        .onAppear(perform: {
            /* App is pushing the next view before this view is fully loaded.
             It resulted with showing next view and going back to this one.
             The async enables app to load this view and then push the next one. */
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                viewModel.connectToAirBeamAndSync(standaloneSessionToSyncAndFinish)
            }
        })
    }
}

extension SyncingABView {
    var navigationLink: some View {
        NavigationLink(
        destination: SDSyncCompleteView(viewModel: SDSyncCompleteViewModelDefault(), creatingSessionFlowContinues: $creatingSessionFlowContinues, isSDClearProcess: false),
            isActive: $viewModel.presentNextScreen,
            label: {
                EmptyView()
            }
        )
    }
}
