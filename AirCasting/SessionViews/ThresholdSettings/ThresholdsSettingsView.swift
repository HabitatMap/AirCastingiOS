//
//  HeatmapSettings.swift
//  AirCasting
//
//  Created by Lunar on 19/01/2021.
//

import SwiftUI
import AirCastingStyling

struct ThresholdsSettingsView: View {
    
    @Binding var thresholdValues: ThresholdsValue
    @Environment(\.presentationMode) var presentationMode
    let initialThresholds: ThresholdsValue
    @StateObject private var thresholdSettingsViewModel: ThresholdSettingsViewModel
    
    init(thresholdValues: Binding<ThresholdsValue>, initialThresholds: ThresholdsValue, threshold: SensorThreshold) {
        _thresholdValues = thresholdValues
        self.initialThresholds = initialThresholds
        _thresholdSettingsViewModel = .init(wrappedValue: ThresholdSettingsViewModel(initialThresholds: initialThresholds, threshold: threshold))
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            mainBody
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(Strings.SessionCart.keyboardToolbarDoneButton) { hideKeyboard() }
                    }
                }
        } else {
            mainBody
                .onTapGesture { hideKeyboard() }
        }
    }
                                                                 
    func showDescriptionLabel(text: String) -> some View {
        Text(text)
            .font(Fonts.muliRegularHeading5)
            .foregroundColor(.aircastingGray)
    }
                                                                 
    func string(_ threshold: Int32) -> String {
                return String(Int(threshold))
    }
    
    func showThresholdTextfield(value: Binding<String>) -> some View {
        TextField("0", text: value)
            .font(Fonts.muliRegularHeading4)
            .foregroundColor(.aircastingGray)
            .multilineTextAlignment(.trailing)
    }
    
    var veryHighTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.veryHigh)
            showThresholdTextfield(value: $thresholdSettingsViewModel.thresholdVeryHigh)
        }
    }
    var highTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.high)
            showThresholdTextfield(value: $thresholdSettingsViewModel.thresholdHigh)
        }
    }
    var mediumTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.medium)
            showThresholdTextfield(value: $thresholdSettingsViewModel.thresholdMedium)
        }
    }
    var lowTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.low)
            showThresholdTextfield(value: $thresholdSettingsViewModel.thresholdLow)
        }
    }
    var veryLowTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.veryLow)
            showThresholdTextfield(value: $thresholdSettingsViewModel.thresholdVeryLow)
        }
    }
    
    var mainBody: some View {
        Form {
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.SessionCart.heatmapSettingsTitle)
                    .foregroundColor(.darkBlue)
                    .font(Fonts.muliHeavyTitle1)
                Text(Strings.SessionCart.heatmapSettingsdescription)
                    .foregroundColor(.aircastingGray)
                    .font(Fonts.moderateRegularHeading2)
            }
            .padding()
            
            Section {
                veryHighTextfield
                highTextfield
                mediumTextfield
                lowTextfield
                veryLowTextfield
            }
            .font(Fonts.moderateRegularHeading2)
            .keyboardType(.numberPad)
            
            VStack {
                Button(action: {
                    thresholdSettingsViewModel.updateToNewThresholds { result in
                        if case .success(let newValues) = result {
                            thresholdValues = newValues
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                })
                {
                    Text(Strings.SessionCart.saveChangesButton)
                        .frame(maxWidth: .infinity)
                        .font(Fonts.muliBoldHeading1)
                }
                .buttonStyle(BlueButtonStyle())
                
                Button(Strings.SessionCart.resetChangesButton, action: {
                    thresholdValues = thresholdSettingsViewModel.resetToDefault()
                    presentationMode.wrappedValue.dismiss()
                })
                .font(Fonts.moderateRegularHeading2)
                .frame(minHeight: 35)
            }
            .listRowBackground(Color.clear)
            .buttonStyle(BorderlessButtonStyle())
        }
        .onAppear {
            thresholdSettingsViewModel.thresholdVeryLow = string(thresholdValues.veryLow)
            thresholdSettingsViewModel.thresholdLow = string(thresholdValues.low)
            thresholdSettingsViewModel.thresholdMedium = string(thresholdValues.medium)
            thresholdSettingsViewModel.thresholdHigh = string(thresholdValues.high)
            thresholdSettingsViewModel.thresholdVeryHigh = string(thresholdValues.veryHigh)
        }
        .alert(item: $thresholdSettingsViewModel.alert, content: { $0.makeAlert() })
    }
}

#if DEBUG
struct HeatmapSettings_Previews: PreviewProvider {
    static var previews: some View {
            ThresholdsSettingsView(thresholdValues: .constant(ThresholdsValue(veryLow: 10,
                                                                              low: 15,
                                                                              medium: 20,
                                                                              high: 25,
                                                                              veryHigh: 30)),
                                   initialThresholds: ThresholdsValue.init(veryLow:  10,
                                                                           low:      15,
                                                                           medium:   20,
                                                                           high:     25,
                                                                           veryHigh: 30),
                                   threshold: .mock)
        }
}
#endif
