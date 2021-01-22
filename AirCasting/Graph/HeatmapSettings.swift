//
//  HeatmapSettings.swift
//  AirCasting
//
//  Created by Lunar on 19/01/2021.
//

import SwiftUI

struct HeatmapSettings: View {
    
    @State private var minValue = ""
    @State private var lowValue = ""
    @State private var mediumValue = ""
    @State private var highValue = ""
    @State private var maxValue = ""
    
    @Binding var changedValues: [Float]
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 16) {
                Text("Heatmap settings")
                    .foregroundColor(.darkBlue)
                    //heavy = extra bold?
                    .font(Font.muli(size: 24, weight: .heavy))
                Text("Values beyoung Min and Max will not be displayed.")
                    .foregroundColor(.aircastingGray)
                    .font(Font.moderate(size: 16, weight: .regular))
            }
            
            Section {
                maxTextfield
                highTextfield
                mediumTextfield
                lowTextfield
                minTextfield
            }
            Button("Save changes", action: {
                saveChanges()
            })
            .frame(width: 300, height: 40, alignment: .center)
            .buttonStyle(BlueButtonStyle())
        }
        .padding()
    }
    
    func saveChanges() {
        let stringValues = [maxValue, highValue, mediumValue, lowValue, minValue]
        var newValues: [Float] = []
        for value in stringValues {
            let convertedValue = convertToFloat(value: value)
            newValues.append(convertedValue)
        }
        changedValues = newValues
    }
    
    func convertToFloat(value: String) -> Float {
        let floatValue = Float(value) ?? 0
        return floatValue
    }
    
    func showDescriptionLabel(text: String) -> some View {
        Text(text)
            .font(Font.muli(size: 13))
            .foregroundColor(.aircastingGray)
    }
    
    func showValuesTextfield(initialValue: String, value: Binding<String>) -> some View {
        TextField(initialValue, text: value)
            .font(Font.muli(size: 14))
            .multilineTextAlignment(.trailing)
    }
    
    var maxTextfield: some View {
        HStack {
            showDescriptionLabel(text: "Max")
            showValuesTextfield(initialValue: "\(changedValues[0])", value: $maxValue)
        }
    }
    var highTextfield: some View {
        HStack {
            showDescriptionLabel(text: "High")
            showValuesTextfield(initialValue: "\(changedValues[1])", value: $highValue)
        }
    }
    var mediumTextfield: some View {
        HStack {
            showDescriptionLabel(text: "Medium")
            showValuesTextfield(initialValue: "\(changedValues[2])", value: $mediumValue)
        }
    }
    
    var lowTextfield: some View {
        HStack {
            showDescriptionLabel(text: "Low")
            showValuesTextfield(initialValue: "\(changedValues[3])", value: $lowValue)
        }
    }
    var minTextfield: some View {
        HStack {
            showDescriptionLabel(text: "Min")
            showValuesTextfield(initialValue: "\(changedValues[4])", value: $minValue)
        }
    }

}

struct HeatmapSettings_Previews: PreviewProvider {
    static var previews: some View {
        HeatmapSettings(changedValues: .constant([130, 90, 40, 30, 20, 0]))
    }
}
