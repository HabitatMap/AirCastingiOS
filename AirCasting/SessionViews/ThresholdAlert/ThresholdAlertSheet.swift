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
                        .padding(.top, 20)
                    description
                    if viewModel.activeAlerts.isReady {
                        chooseStream
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.vertical)
                    }
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
        VStack(alignment: .leading, spacing: 20) {
            ForEach(viewModel.streamOptions) { option in
                ThresholdAlertStreamOption(
                    isOn: option.isOn,
                    thresholdValue: .init( get: { option.thresholdValue}, set: { viewModel.changeThreshold(of: option.id, to: $0) }),
                    frequency: .init( get: { option.frequency}, set: { viewModel.changeFrequency(of: option.id, to: $0) }),
                    streamName: option.shortSensorName
                ) { isOn in
                    viewModel.changeIsOn(of: option.id, to: isOn)
                }
                !option.valid && option.isOn ? Text(Strings.ThresholdAlertSheet.invalidThresholdMessage).foregroundColor(.red) : nil
            }
        }.padding()
    }
    
    
    
    private var continueButton: some View {
        Button {
            viewModel.save {
                isActive = false
            }
        } label: {
            Text(Strings.ThresholdAlertSheet.saveButton)
                .font(Fonts.muliBoldHeading1)
        }
        .buttonStyle(BlueButtonStyle())
        .disabled(!viewModel.saveButtonEnabled)
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
