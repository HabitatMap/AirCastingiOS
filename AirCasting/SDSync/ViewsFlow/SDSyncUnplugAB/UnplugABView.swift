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
        GeometryReader { reader in
            VStack(alignment: .leading, spacing: 40) {
                ProgressView(value: 0.426)
                Spacer()
                HStack() {
                    Spacer()
                    unplugImage
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
            .background(navigationLink)
            .padding()
        }
    }
}

extension UnplugABView {
    
    var unplugImage: some View {
        Image("airbeam-unplugged")
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(Strings.UnplugAirbeamView.title)
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.UnplugAirbeamView.message)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
            .minimumScaleFactor(0.8)
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
