//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import SwiftUI

struct SessionCell: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            dateAndTime
            nameLabelAndExpandButton
            measurementsTitle
            measurements
                .padding(.horizontal, 15)
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
        .padding()
        .frame(height: 190)
        .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1)
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
                Button("v") {}
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
        HStack() {
            VStack {
                Text("PM1")
                    .font(Font.moderate(size: 13, weight: .regular))
                Text("23")
                    .font(Font.moderate(size: 14, weight: .regular))
            }
            VStack {
                Text("PM2.5")
                    .font(Font.moderate(size: 13, weight: .regular))
                    Text("23")
                        .font(Font.moderate(size: 14, weight: .regular))
            }
            VStack {
                Text("PM10")
                    .font(Font.moderate(size: 13, weight: .regular))
                Text("23")
                    .font(Font.moderate(size: 14, weight: .regular))
            }
            VStack {
                Text("F")
                    .font(Font.moderate(size: 13, weight: .regular))
                Text("23")
                    .font(Font.moderate(size: 14, weight: .regular))
            }
            VStack {
                Text("RH")
                    .font(Font.moderate(size: 13, weight: .regular))
                Text("23")
                    .font(Font.moderate(size: 14, weight: .regular))
            }
        }
    }
}

struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        SessionCell()
    }
}
