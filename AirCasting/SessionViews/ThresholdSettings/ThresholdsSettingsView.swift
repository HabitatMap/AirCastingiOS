//
//  HeatmapSettings.swift
//  AirCasting
//
//  Created by Lunar on 19/01/2021.
//

import SwiftUI
import AirCastingStyling

struct ThresholdsSettingsView: View {
    
    @Binding var thresholdValues: [Float]
    @Environment(\.presentationMode) var presentationMode
    let initialThresholds: [Int32]
    @StateObject private var thresholdSettingsViewModel: ThresholdSettingsViewModel
    
    init(thresholdValues: Binding<[Float]>, initialThresholds: [Int32]) {
        _thresholdValues = thresholdValues
        self.initialThresholds = initialThresholds
        _thresholdSettingsViewModel = .init(wrappedValue: ThresholdSettingsViewModel(initialThresholds: initialThresholds))
    }
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.SessionCart.heatmapSettingsTitle)
                    .foregroundColor(.darkBlue)
                    .font(Fonts.heavyTitle1)
                Text(Strings.SessionCart.heatmapSettingsdescription)
                    .foregroundColor(.aircastingGray)
                    .font(Fonts.regularHeading2)
            }
            .padding()
            
            Section {
                veryHighTextfield
                highTextfield
                mediumTextfield
                lowTextfield
                veryLowTextfield
            }
            
            VStack {
                Button(action: {
                    thresholdValues = thresholdSettingsViewModel.updateToNewThresholds()
                    presentationMode.wrappedValue.dismiss()
                })
                {
                    Text(Strings.SessionCart.saveChangesButton)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BlueButtonStyle())
                
                Button(Strings.SessionCart.resetChangesButton, action: {
                    thresholdValues = thresholdSettingsViewModel.resetToDefault()
                    presentationMode.wrappedValue.dismiss()
                })
                    .frame(minHeight: 35)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .onAppear {
            thresholdSettingsViewModel.thresholdVeryLow = string(thresholdValues[0])
            thresholdSettingsViewModel.thresholdLow = string(thresholdValues[1])
            thresholdSettingsViewModel.thresholdMedium = string(thresholdValues[2])
            thresholdSettingsViewModel.thresholdHigh = string(thresholdValues[3])
            thresholdSettingsViewModel.thresholdVeryHigh = string(thresholdValues[4])
        }
    }
                                                                 
    func showDescriptionLabel(text: String) -> some View {
        Text(text)
            .font(Fonts.muliHeading4)
            .foregroundColor(.aircastingGray)
    }
                                                                 
    func string(_ threshold: Float) -> String {
                return String(Int(threshold))
    }
    
    func showThresholdTextfield(value: Binding<String>) -> some View {
        TextField("0", text: value)
            .font(Fonts.muliHeading3)
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
}

#if DEBUG
struct HeatmapSettings_Previews: PreviewProvider {
    static var previews: some View {
        ThresholdsSettingsView(thresholdValues: .constant([0, 20, 30, 40, 50]),
                               initialThresholds: [])
    }
}
#endif
