// Created by Lunar on 01/08/2022.
//

import SwiftUI
import AirCastingStyling

struct ThresholdAlertSheet<VM: ThresholdAlertSheetViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var isActive: Bool
    
    var body: some View {
        ZStack {
            XMarkButton()
            VStack(alignment: .leading, spacing: 20) {
                title
                description
                chooseStream
                continueButton
                cancelButton
            }
            .padding()
        }
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
    
    private var title: some View {
        Text(Strings.ThresholdAlertSheet.title)
            .font(Fonts.muliHeavyTitle1)
            .foregroundColor(.darkBlue)
    }
    
    private var description: some View {
        Text(Strings.ThresholdAlertSheet.description)
            .font(Fonts.moderateRegularHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    private var onOffToggle: some View {
        Toggle("Turn on", isOn: $viewModel.isOn)
    }
    
    private var chooseStream: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.streamOptions, id: \.id) { option in
                HStack {
                    CheckBox(isSelected: option.isSelected).onTapGesture {
                        viewModel.didSelect(option: option)
                    }
                    Text(option.title)
                        .font(Fonts.muliBoldHeading1)
                }
            }
        }.padding()
    }
    
    private var continueButton: some View {
        Button {
            viewModel.confirmationButtonPressed()
        } label: {
            Text(Strings.DeleteSession.continueButton)
                .font(Fonts.muliBoldHeading1)
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    private var cancelButton: some View {
        Button {
            isActive.toggle()
        } label: {
            Text(Strings.Commons.cancel)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
}

struct ThresholdAlertSheet_Previews: PreviewProvider {
    static var previews: some View {
        ThresholdAlertSheet(viewModel: ThresholdAlertSheetViewModel(session: SessionEntity.mock, apiClient: ShareSessionApi(), exitRoute: { _ in }), isActive: .constant(true))
    }
}
