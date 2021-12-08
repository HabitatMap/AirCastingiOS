// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct SDRestartABView<VM: SDRestartABViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var sessionContext: CreateSessionContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.3)
            Spacer()
            HStack() {
                Spacer()
                restartImage
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
        .background(
            Group {
                selectDeviceLink
            })
        .padding()
        .onAppear(perform: { sessionContext.deviceType = .AIRBEAM3 })
    }
}

extension SDRestartABView {
    
    var restartImage: some View {
        Image("2-power")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(Strings.SDRestartABView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.SDRestartABView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var continueButton: some View {
        Button {
            viewModel.presentNextScreen.toggle()
        } label: {
            Text(Strings.ABConnectedView.continueButton)
        }.buttonStyle(BlueButtonStyle())
    }

    var selectDeviceLink: some View {
        NavigationLink(
            destination: SelectPeripheralView(SDClearingRouteProcess: viewModel.isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: viewModel.urlProvider, syncMode: !viewModel.isSDClearProcess),
            isActive: $viewModel.presentNextScreen,
            label: {
                EmptyView()
            })
    }
}
