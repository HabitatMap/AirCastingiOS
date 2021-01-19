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
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 16) {
                Text("Heatmap settings")
                    .foregroundColor(.darkBlue)
                    //powinno być ekstra bold, dlaczego nie jest?
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
        }
        .padding()
    }
    
    var maxTextfield: some View {
        HStack {
            Text("Max")
                .font(Font.muli(size: 13))
                .foregroundColor(.aircastingGray)
            TextField("130", text: $maxValue)
                .font(Font.muli(size: 14))
                .multilineTextAlignment(.trailing)
        }
    }
    var highTextfield: some View {
        HStack {
            Text("High")
                .font(Font.muli(size: 13))
                .foregroundColor(.aircastingGray)
            TextField("90", text: $highValue)
                .font(Font.muli(size: 14))
                .multilineTextAlignment(.trailing)
        }
    }
    var mediumTextfield: some View {
        HStack {
            Text("Medium")
                .font(Font.muli(size: 13))
                .foregroundColor(.aircastingGray)
            TextField("65", text: $mediumValue)
                .font(Font.muli(size: 14))
                .multilineTextAlignment(.trailing)
        }
    }
    var lowTextfield: some View {
        HStack {
            Text("Low")
                .font(Font.muli(size: 13))
                .foregroundColor(.aircastingGray)
            TextField("30", text: $lowValue)
                .font(Font.muli(size: 14))
                .multilineTextAlignment(.trailing)
        }
    }
    var minTextfield: some View {
        HStack {
            Text("Min")
                .font(Font.muli(size: 13))
                .foregroundColor(.aircastingGray)
            TextField("0", text: $minValue)
                .font(Font.muli(size: 14))
                .multilineTextAlignment(.trailing)
        }
    }

}

struct HeatmapSettings_Previews: PreviewProvider {
    static var previews: some View {
        HeatmapSettings()
    }
}
