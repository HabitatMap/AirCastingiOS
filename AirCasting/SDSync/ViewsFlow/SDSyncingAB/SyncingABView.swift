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
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.7)
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
        .onReceive(viewModel.isSyncCompleted, perform: { isConnected in
            viewModel.presentNextScreen = isConnected
        })
        .onReceive(viewModel.shouldDismiss, perform: { dismiss in
            viewModel.presentAlert = dismiss
        })
        .alert(isPresented: $viewModel.presentAlert, content: { connectionTimeOutAlert })
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
        Text(Strings.SyncingABView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.SyncingABView.message)
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
    
    var connectionTimeOutAlert: Alert {
        Alert(title: Text(Strings.SyncingABView.alertTitle),
              message: Text(Strings.SyncingABView.alertMessage),
              dismissButton: .default(Text(Strings.AirBeamConnector.connectionTimeoutActionTitle), action: {
            presentationMode.wrappedValue.dismiss()
        }))
    }
    
    var navigationLink: some View {
        NavigationLink(
            destination: SDSyncCompleteView(creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: $viewModel.presentNextScreen,
            label: {
                EmptyView()
            }
        )
    }
}
