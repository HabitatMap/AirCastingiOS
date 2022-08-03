// Created by Lunar on 03/08/2022.
//

import SwiftUI

struct ThresholdAlertStreamOption: View {
    @Binding var isOn: Bool
    @Binding var thresholdValue: String
    var streamName = "PM2.5"
    
    var body: some View {
        HStack {
            Toggle(isOn: $isOn, label: {
                Text(streamName)
            })
            Spacer()
            if isOn {
                createTextfield(placeholder: Strings.ThresholdAlertSheet.thresholdLabel, binding: $thresholdValue)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
            }
        }
    }
    
    private func createLabel(with text: String) -> some View {
        Text(text)
            .font(Fonts.muliBoldHeading2)
            .foregroundColor(.aircastingDarkGray)
    }
}

struct ThresholdAlertStreamOption_Previews: PreviewProvider {
    static var previews: some View {
        ThresholdAlertStreamOption(isOn: .constant(false), thresholdValue: .constant("6"))
    }
}
