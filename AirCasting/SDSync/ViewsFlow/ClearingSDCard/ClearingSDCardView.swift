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
        ProgressFlowAB(progress: 0.7, abImage: ABCircleAndLoader(), title: Strings.ClearingSDCardView.title, message: Strings.ClearingSDCardView.message)
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .onReceive(viewModel.shouldDismiss, perform: { value in
            if value {
                presentationMode.wrappedValue.dismiss()
            }
        })
        .onAppear(perform: {
            viewModel.clearSDCardButtonTapped()
        })
        .background(navigationLink)
    }
}

extension ClearingSDCardView {
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
