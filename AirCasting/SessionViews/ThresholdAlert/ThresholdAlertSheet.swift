// Created by Lunar on 01/08/2022.
//

import SwiftUI
import AirCastingStyling

struct ThresholdAlertSheet<VM: ThresholdAlertSheetViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var isActive: Bool
    
    var body: some View {
        ScrollView {
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
    
    private var chooseStream: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.streamOptions) { option in
                ThresholdAlertStreamOption(
                    isOn: .init( get: { option.isOn}, set: { viewModel.changeIsOn(of: option.id, to: $0) }),
                    thresholdValue: .init( get: { option.thresholdValue}, set: { viewModel.changeThreshold(of: option.id, to: $0) }),
                    frequency: .init( get: { option.frequency}, set: { viewModel.changeFrequency(of: option.id, to: $0) }),
                    streamName: option.shortStreamName
                )
            }
        }.padding()
    }
    
    
    
    private var continueButton: some View {
        Button {
            viewModel.confirmationButtonPressed()
        } label: {
            Text(Strings.ThresholdAlertSheet.saveButton)
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
        ThresholdAlertSheet(viewModel: ThresholdAlertSheetViewModel(session: SessionEntity.mock, apiClient: ShareSessionApi()), isActive: .constant(true))
    }
}
