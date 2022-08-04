// Created by Lunar on 03/08/2022.
//

import SwiftUI

struct ThresholdAlertStreamOption: View {
    @Binding var isOn: Bool
    @Binding var thresholdValue: String
    @Binding var frequency: ThresholdAlertFrequency
    var streamName = "PM2.5"
    
    var body: some View {
        mainBody
            .onTapGesture { hideKeyboard() }
    }
    
    private var mainBody: some View {
        VStack {
            HStack {
                Toggle(isOn: $isOn, label: {
                    Text(streamName)
                        .font(Fonts.muliMediumHeading1)
                })
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
            if isOn {
                HStack {
                    createTextfield(placeholder: Strings.ThresholdAlertSheet.thresholdLabel, binding: $thresholdValue)
                        .font(Fonts.moderateRegularHeading2)
                        .keyboardType(.decimalPad)
                    frequencyPicker
                }
            }
        }
    }
    
    private func createLabel(with text: String) -> some View {
        Text(text)
            .font(Fonts.muliBoldHeading2)
            .foregroundColor(.aircastingDarkGray)
    }
    
    private var frequencyPicker: some View {
        HStack {
            Picker(Strings.ThresholdAlertSheet.frequencyLabel, selection: $frequency) {
                Text("1 hour").tag(ThresholdAlertFrequency.oneHour)
                Text("24 hours").tag(ThresholdAlertFrequency.twentyFourHours)
            }
            .font(Fonts.moderateRegularHeading2)
            .pickerStyle(.segmented)
        }
    }
}

struct ThresholdAlertStreamOption_Previews: PreviewProvider {
    static var previews: some View {
        ThresholdAlertStreamOption(isOn: .constant(true), thresholdValue: .constant("6"), frequency: .constant(.oneHour))
    }
}
