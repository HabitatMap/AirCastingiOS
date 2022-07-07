// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct SDRestartABView: View {
    @StateObject private var viewModel: SDRestartABViewModel
    @Binding private var creatingSessionFlowContinues: Bool
    
    init(isSDClearProcess: Bool, creatingSessionFlowContinues: Binding<Bool>) {
        self._creatingSessionFlowContinues = .init(projectedValue: creatingSessionFlowContinues)
        self._viewModel = .init(wrappedValue: .init(isSDClearProcess: isSDClearProcess))
    }
    
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
        .background(selectDeviceLink)
        .padding()
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
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.SDRestartABView.message)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var continueButton: some View {
        Button {
            viewModel.continueSyncFlow()
        } label: {
            Text(Strings.Commons.continue)
        }.buttonStyle(BlueButtonStyle())
    }

    var selectDeviceLink: some View {
        NavigationLink(
            destination: SelectPeripheralView(SDClearingRouteProcess: viewModel.isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues, syncMode: !viewModel.isSDClearProcess),
            isActive: $viewModel.presentNextScreen,
            label: {
                EmptyView()
            })
    }
}
