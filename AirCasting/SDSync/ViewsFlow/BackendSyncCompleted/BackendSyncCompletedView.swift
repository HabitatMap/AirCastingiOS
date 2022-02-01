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
        .background(Group { restartNavigationLink; BTNavigationLink })
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
            viewModel.continueButtonTapped()
        } label: {
            Text(Strings.Commons.continue)
        }.buttonStyle(BlueButtonStyle())
    }

    var restartNavigationLink: some View {
        NavigationLink(
            destination: UnplugABView(viewModel: UnplugABViewModelDefault(urlProvider: viewModel.urlProvider, isSDClearProcess: false), creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: .init(get: { viewModel.presentRestartNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }

    var BTNavigationLink: some View {
        NavigationLink(
            destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sdSyncContinues: .constant(true), locationHandler: DummyDefaultLocationHandler(), urlProvider: viewModel.urlProvider),
            isActive: .init(get: { viewModel.presentBTNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }
}
