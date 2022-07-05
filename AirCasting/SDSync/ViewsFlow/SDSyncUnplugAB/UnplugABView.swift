// Created by Lunar on 08/12/2021.
//

import AirCastingStyling
import SwiftUI

struct UnplugABView: View {
    @StateObject private var viewModel: UnplugABViewModel
    @Binding private var creatingSessionFlowContinues: Bool
    
    init(isSDClearProcess: Bool, creatingSessionFlowContinues: Binding<Bool>) {
        self._creatingSessionFlowContinues = .init(projectedValue: creatingSessionFlowContinues)
        self._viewModel = .init(wrappedValue: .init(isSDClearProcess: isSDClearProcess))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.426)
            Spacer()
            HStack() {
                Spacer()
                unplugImage
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

extension UnplugABView {
    
    var unplugImage: some View {
        Image("airbeam-unplugged")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(Strings.UnplugAirbeamView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.UnplugAirbeamView.message)
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
    
    var navigationLink: some View {
        NavigationLink(
            destination: SDRestartABView(isSDClearProcess: viewModel.isSDClearProcess, creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: .init(get: { viewModel.presentNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }
}
