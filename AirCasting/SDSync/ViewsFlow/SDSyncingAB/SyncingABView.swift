//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI

struct SyncingABView<VM: SDSyncViewModel>: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: VM
    @State var progressTitle: String?
    @State var progressCount: String?
    @Binding var creatingSessionFlowContinues: Bool

    var body: some View {
        VStack(spacing: 40) {
            ProgressView(value: 0.852)
            Spacer()
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom), content: {
                syncingImage
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
        .background(Color.aircastingBackgroundWhite.ignoresSafeArea())
        .onReceive(viewModel.progress, perform: { newProgress in
            if let progress = newProgress {
                self.progressTitle = progress.title
                self.progressCount = "\(progress.current)/\(progress.total)"
            }
        })
        .alert(isPresented: $viewModel.presentFailedSyncAlert, content: { connectionTimeOutAlert })
        .onAppear(perform: {
            /* App is pushing the next view before this view is fully loaded.
             It resulted with showing next view and going back to this one.
             The async enables app to load this view and then push the next one. */
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                viewModel.connectToAirBeamAndSync()
            }
        })
    }
}

extension SyncingABView {
    var syncingImage: some View {
        Image("airbeam")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    var titleLabel: some View {
        VStack(alignment: .leading) {
            if viewModel.isDownloadingFinished {
                Text(Strings.SyncingABView.finishingSyncTitle)
            } else {
                progressTitle != nil ? Text("Syncing " + progressTitle!.lowercased()) : Text(Strings.SyncingABView.startingSyncTitle)
                Text(progressCount ?? "")
            }
        }
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.SyncingABView.message)
            .font(Fonts.moderateRegularHeading1)
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

    var connectionTimeOutAlert: Alert {
        Alert(title: Text(Strings.SyncingABView.alertTitle),
              message: Text(Strings.SyncingABView.alertMessage),
              dismissButton: .default(Text(Strings.Commons.gotIt), action: {
            presentationMode.wrappedValue.dismiss()
        }))
    }

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
