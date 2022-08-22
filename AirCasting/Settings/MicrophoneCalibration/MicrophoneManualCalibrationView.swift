// Created by Lunar on 17/08/2022.
//

import Resolver
import AirCastingStyling
import SwiftUI

struct MicrophoneManualCalibrationView: View {
    @StateObject private var viewModel: MicrophoneManualCalibrationViewModel
    
    init(exitRoute: @escaping () -> Void) {
        self._viewModel = .init(wrappedValue: .init(exitRoute: exitRoute))
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Group {
                title.padding(.top, 30)
                Spacer()
                createTextfield(placeholder: "", binding: $viewModel.text)
                    .keyboardType(.numberPad)
                Spacer()
                okButton
                    .disabled(!viewModel.okButtonEnabled)
                cancelButton.padding(.bottom, 30)
            }.padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.aircastingBackground)
    }
    
    private var title: some View {
        Text(Strings.MicrophoneCalibration.title)
            .foregroundColor(.darkBlue)
            .font(Fonts.muliSemiboldTitle1)
    }
    
    private var okButton: some View {
        Button { viewModel.okTapped() } label: {
            Text(Strings.Commons.ok)
        }.buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button { viewModel.cancelTapped() } label: {
            Text(Strings.Commons.cancel)
        }.buttonStyle(BlueTextButtonStyle())
    }
}
