//
//  HeatmapSettings.swift
//  AirCasting
//
//  Created by Lunar on 19/01/2021.
//

import SwiftUI

struct HeatmapSettingsView: View {
    
    @State private var minValue = ""
    @State private var lowValue = ""
    @State private var mediumValue = ""
    @State private var highValue = ""
    @State private var maxValue = ""
    @Binding var changedValues: [Float]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 16) {
                Text("Heatmap settings")
                    .foregroundColor(.darkBlue)
                    //heavy = extra bold?
                    .font(Font.muli(size: 24, weight: .heavy))
                Text("Values beyond Min and Max will not be displayed.")
                    .foregroundColor(.aircastingGray)
                    .font(Font.moderate(size: 16, weight: .regular))
            }
            .padding()
            
            Section {
                maxTextfield
                highTextfield
                mediumTextfield
                lowTextfield
                minTextfield
            }
            
            VStack {
                Button(action: {
                    saveChanges()
                    presentationMode.wrappedValue.dismiss()
                })
                {
                    Text("Save changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BlueButtonStyle())
                
                Button("Reset to default", action: {
                    presentationMode.wrappedValue.dismiss()
                })
                .frame(minHeight: 35)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .onAppear {
            minValue = "\(Int(changedValues[0]))"
            lowValue = "\(Int(changedValues[1]))"
            mediumValue = "\(Int(changedValues[2]))"
            highValue = "\(Int(changedValues[3]))"
            maxValue = "\(Int(changedValues[4]))"
        }
    }
    
    func saveChanges() {
        let stringValues = [maxValue, highValue, mediumValue, lowValue, minValue]
        var newValues: [Float] = []
        for value in stringValues {
            let convertedValue = convertToFloat(value: value)
            newValues.append(convertedValue)
        }
        let sortedValues = newValues.sorted { $0 < $1 }
        changedValues = sortedValues
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
    
    func showValuesTextfield(value: Binding<String>) -> some View {
        TextField("0", text: value)
            .font(Font.muli(size: 14))
            .foregroundColor(.aircastingGray)
            .multilineTextAlignment(.trailing)
    }
    
    var maxTextfield: some View {
        HStack {
            showDescriptionLabel(text: "Max")
            showValuesTextfield(value: $maxValue)
        }
    }
    var highTextfield: some View {
        HStack {
            showDescriptionLabel(text: "High")
            showValuesTextfield(value: $highValue)
        }
    }
    var mediumTextfield: some View {
        HStack {
            showDescriptionLabel(text: "Medium")
            showValuesTextfield(value: $mediumValue)
        }
    }
    
    var lowTextfield: some View {
        HStack {
            showDescriptionLabel(text: "Low")
            showValuesTextfield(value: $lowValue)
        }
    }
    var minTextfield: some View {
        HStack {
            showDescriptionLabel(text: "Min")
            showValuesTextfield(value: $minValue)
        }
    }

}

struct HeatmapSettings_Previews: PreviewProvider {
    static var previews: some View {
        HeatmapSettingsView(changedValues: .constant([0, 20, 30, 40, 50]))
    }
}
