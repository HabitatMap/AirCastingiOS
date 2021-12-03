// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct BackendSyncCompletedView<VM: BackendSyncCompletedViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.2)
            Spacer()
            HStack() {
                Spacer()
                connectedImage
                Spacer()
            }
            Spacer()
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
            Spacer()
        }
        .background(navigationLink)
        .padding()
    }
}

private extension BackendSyncCompletedView {
    
    var connectedImage: some View {
        Image("4-connected")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(Strings.SDSyncSuccessView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.SDSyncSuccessView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var continueButton: some View {
        Button {
            viewModel.presentNextScreen = true
        } label: {
            Text(Strings.ABConnectedView.continueButton)
        }.buttonStyle(BlueButtonStyle())
    }
    
    var navigationLink: some View {
        NavigationLink(
            destination: SDRestartABView(viewModel: SDRestartABViewModelDefault(urlProvider: viewModel.urlProvider), creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: $viewModel.presentNextScreen,
            label: {
                EmptyView()
            })
    }
}
