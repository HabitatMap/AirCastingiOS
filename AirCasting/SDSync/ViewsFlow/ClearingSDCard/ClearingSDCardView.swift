//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI

struct ClearingSDCardView<VM: ClearingSDCardViewModel>: View {
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
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                viewModel.presentNextScreen.toggle()
            }
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
