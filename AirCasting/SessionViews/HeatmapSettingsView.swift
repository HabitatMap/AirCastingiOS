//
//  HeatmapSettings.swift
//  AirCasting
//
//  Created by Lunar on 19/01/2021.
//

import SwiftUI
import AirCastingStyling

struct HeatmapSettingsView: View {
    
    @State private var thresholdVeryLow = ""
    @State private var thresholdLow = ""
    @State private var thresholdMedium = ""
    @State private var thresholdHigh = ""
    @State private var thresholdVeryHigh = ""
    @Binding var changedThresholdValues: [Float]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.SessionCart.heatmapSettingsTitle)
                    .foregroundColor(.darkBlue)
                    .font(Fonts.HeatmapSettingsView.heatmapTitle)
                Text(Strings.SessionCart.heatmapSettingsdescription)
                    .foregroundColor(.aircastingGray)
                    .font(Fonts.HeatmapSettingsView.heatmapDescription)
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
                    saveChanges()
                    presentationMode.wrappedValue.dismiss()
                })
                {
                    Text(Strings.SessionCart.saveChangesButton)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BlueButtonStyle())
                
                Button(Strings.SessionCart.resetChangesButton, action: {
                    presentationMode.wrappedValue.dismiss()
                })
                .frame(minHeight: 35)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .onAppear {
            thresholdVeryLow = "\(Int(changedThresholdValues[0]))"
            thresholdLow = "\(Int(changedThresholdValues[1]))"
            thresholdMedium = "\(Int(changedThresholdValues[2]))"
            thresholdHigh = "\(Int(changedThresholdValues[3]))"
            thresholdVeryHigh = "\(Int(changedThresholdValues[4]))"
        }
    }
    
    func saveChanges() {
        let stringThresholdValues = [thresholdVeryHigh, thresholdHigh, thresholdMedium, thresholdLow, thresholdVeryLow]
        var newThresholdValues: [Float] = []
        for value in stringThresholdValues {
            let convertedValue = convertToFloat(value: value)
            newThresholdValues.append(convertedValue)
        }
        let sortedThresholdValues = newThresholdValues.sorted { $0 < $1 }
        changedThresholdValues = sortedThresholdValues
    }
    
    func convertToFloat(value: String) -> Float {
        let floatValue = Float(value) ?? 0
        return floatValue
    }
    
    func showDescriptionLabel(text: String) -> some View {
        Text(text)
            .font(Fonts.HeatmapSettingsView.showDescription)
            .foregroundColor(.aircastingGray)
    }
    
    func showThresholdTextfield(value: Binding<String>) -> some View {
        TextField("0", text: value)
            .font(Fonts.HeatmapSettingsView.showThreshold)
            .foregroundColor(.aircastingGray)
            .multilineTextAlignment(.trailing)
    }
    
    var veryHighTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.veryHigh)
            showThresholdTextfield(value: $thresholdVeryHigh)
        }
    }
    var highTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.high)
            showThresholdTextfield(value: $thresholdHigh)
        }
    }
    var mediumTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.medium)
            showThresholdTextfield(value: $thresholdMedium)
        }
    }
    
    var lowTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.low)
            showThresholdTextfield(value: $thresholdLow)
        }
    }
    var veryLowTextfield: some View {
        HStack {
            showDescriptionLabel(text: Strings.Thresholds.veryLow)
            showThresholdTextfield(value: $thresholdVeryLow)
        }
    }

}

struct HeatmapSettings_Previews: PreviewProvider {
    static var previews: some View {
        HeatmapSettingsView(changedThresholdValues: .constant([0, 20, 30, 40, 50]))
    }
}
