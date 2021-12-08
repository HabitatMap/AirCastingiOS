//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI

struct ClearingSDCardView<VM: ClearingSDCardViewModel>: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: VM
    @State private var showAlert = false
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
        .alert(isPresented: $showAlert) {
            alert
        }
        .onAppear(perform: {
            viewModel.clearSDCard()
        })
        .onReceive(viewModel.isClearingCompleted, perform: { result in
            viewModel.presentNextScreen = result
        })
        .onReceive(viewModel.shouldDismiss, perform: { result in
            showAlert = result
        })
        .padding()
        .background(navigationLink)
    }
}

extension ClearingSDCardView {
    var syncingImage: some View {
        Image("airbeam")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(Strings.ClearingSDCardView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.ClearingSDCardView.message)
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
    
    var alert: Alert {
        Alert(title: Text("\(viewModel.getAlertTitle())"),
              message: Text("\(viewModel.getAlertMessage())"),
              dismissButton: .default(Text(Strings.AirBeamConnector.connectionTimeoutActionTitle), action: {
            presentationMode.wrappedValue.dismiss()
        }))
    }
    
    var navigationLink: some View {
        NavigationLink(
            destination: SDSyncCompleteView(creatingSessionFlowContinues: $creatingSessionFlowContinues, isSDClearProcess: viewModel.isSDClearProcess),
            isActive: $viewModel.presentNextScreen,
            label: {
                EmptyView()
            }
        )
    }
}
