// Created by Lunar on 08/12/2021.
//

import AirCastingStyling
import SwiftUI

struct UnplugABView<VM: UnplugABViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.3)
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
            destination: SDRestartABView(viewModel: SDRestartABViewModelDefault(urlProvider: viewModel.urlProvider, isSDClearProcess: viewModel.isSDClearProcess), creatingSessionFlowContinues: $creatingSessionFlowContinues),
            isActive: .init(get: { viewModel.presentNextScreen }, set: { _ in }),
            label: {
                EmptyView()
            })
    }
}

#if DEBUG
struct UnplugAirBeamView_Previews: PreviewProvider {
    static var previews: some View {
        UnplugABView(viewModel: UnplugABViewModelDummy(), creatingSessionFlowContinues: .constant(false))
    }
}
#endif
