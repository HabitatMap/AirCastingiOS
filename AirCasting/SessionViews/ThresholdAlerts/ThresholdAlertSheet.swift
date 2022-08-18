// Created by Lunar on 01/08/2022.
//

import SwiftUI
import AirCastingStyling

struct ThresholdAlertSheet: View {
    @StateObject var viewModel: ThresholdAlertSheetViewModel
    @Binding var isActive: Bool
    @Environment(\.presentationMode) private var presentationMode
    
    init(session: Sessionable, isActive: Binding<Bool>) {
        _viewModel = .init(wrappedValue: ThresholdAlertSheetViewModel(session: session))
        _isActive = .init(projectedValue: isActive)
    }
    
    var body: some View {
        LoadingView(isShowing: $viewModel.loading) {
            ScrollView {
                ZStack {
                    XMarkButton()
                    VStack(alignment: .leading, spacing: 20) {
                        title
                            .padding(.top, 20)
                        description
                        chooseStream
                        continueButton
                        cancelButton
                    }
                    .padding()
                }
            }
        }
        .background(Color.aircastingBackground.ignoresSafeArea())
        .onChange(of: viewModel.shouldDismiss) {
            $0 ? presentationMode.wrappedValue.dismiss() : ()
        }
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
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
                    thresholdValue: .init( get: { option.thresholdValue }, set: { viewModel.changeThreshold(of: option.id, to: $0) }),
                    frequency: .init( get: { option.frequency }, set: { viewModel.changeFrequency(of: option.id, to: $0) }),
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
            Text(viewModel.saveButtonText)
                .font(Fonts.muliBoldHeading1)
        }
        .buttonStyle(BlueButtonStyle())
        .disabled(viewModel.isSaving)
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

#if DEBUG
struct ThresholdAlertSheet_Previews: PreviewProvider {
    static var previews: some View {
        ThresholdAlertSheet(session: SessionEntity.mock, isActive: .constant(true))
    }
}
#endif
