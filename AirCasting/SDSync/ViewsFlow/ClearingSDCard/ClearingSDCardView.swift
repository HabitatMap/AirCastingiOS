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
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .onReceive(viewModel.shouldDismiss, perform: { value in
            if value {
                presentationMode.wrappedValue.dismiss()
            }
        })
        .onAppear(perform: {
            viewModel.clearSDCardButtonTapped()
        })
        .padding()
        .background(navigationLink)
        .background(Color.aircastingBackgroundWhite.ignoresSafeArea())
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
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.ClearingSDCardView.message)
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
    
    var navigationLink: some View {
        NavigationLink(
            destination: SDSyncCompleteView(viewModel: SDSyncCompleteViewModelDefault(), creatingSessionFlowContinues: $creatingSessionFlowContinues, isSDClearProcess: viewModel.isSDClearProcess),
            isActive: $viewModel.presentNextScreen,
            label: {
                EmptyView()
            }
        )
    }
}
