// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct BackendSyncCompletedView<VM: BackendSyncCompletedViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        GeometryReader { reader in
            VStack(alignment: .leading, spacing: 40) {
                ProgressView(value: 0.2)
                Spacer()
                HStack() {
                    Spacer()
                    connectedImage
                        .frame(width: reader.size.width / 2, height: reader.size.height / 3, alignment: .center)
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
}

private extension BackendSyncCompletedView {
    
    var connectedImage: some View {
        Image("4-connected")
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
            destination: UnplugABView(isSDClearProcess: false, creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: .init(get: { viewModel.presentRestartNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }
    
    var BTNavigationLink: some View {
        NavigationLink(
            destination: TurnOnBluetoothView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sdSyncContinues: .constant(true)),
            isActive: .init(get: { viewModel.presentBTNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }
}
