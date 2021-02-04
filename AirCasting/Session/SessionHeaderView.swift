//
//  SessionHeader.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct SessionHeaderView: View {
    
    let action: () -> Void
    let isExpandButtonNeeded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13){
            dateAndTime
            nameLabelAndExpandButton
            measurementsTitle
            measurements
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
    }
    
    var dateAndTime: some View {
        Text("03/20/2020 10:35-15:56")
    }
    
    var nameLabelAndExpandButton: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Neighborhood check")
                    .font(Font.moderate(size: 18, weight: .bold))
                Spacer()
                if isExpandButtonNeeded {
                    Button(action: {
                        action()
                    }) {
                        Image("expandButtonIcon")
                            .renderingMode(.original)
                    }
                }
            }
            Text("Fixed, AirBeam3")
                .font(Font.moderate(size: 13, weight: .regular))
        }
        .foregroundColor(.darkBlue)
    }
    
    var measurementsTitle: some View {
        Text("Most recent measurement:")
    }
    
    var measurements: some View {
        HStack {
            Group {
                singleMeasurement(name: "PM1", value: 23)
                singleMeasurement(name: "PM2", value: 1)
                singleMeasurement(name: "PM10", value: 23)
                singleMeasurement(name: "F", value: 10)
                singleMeasurement(name: "RH", value: 23)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func singleMeasurement(name: String, value: Int) -> some View {
        VStack(spacing: 3) {
            Text(name)
                .font(Font.system(size: 13))
            HStack(spacing: 3){
                Color.green
                    .clipShape(Circle())
                    .frame(width: 5, height: 5)
                Text("\(value)")
                    .font(Font.moderate(size: 14, weight: .regular))
            }
        }
    }
}

struct SessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SessionHeaderView(action: {}, isExpandButtonNeeded: true)    }
}
