//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import SwiftUI

struct SessionCell: View {
    
    @State private var isCollapsed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            dateAndTime
            nameLabelAndExpandButton
            measurementsTitle
            measurements
            if !isCollapsed {
                pollutionChart
            }
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Color.white
                .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1)
        )
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
                Button(action: {
                        withAnimation {
                            isCollapsed = !isCollapsed
                        }
                }) {
                    Image("expandButtonIcon")
                        .renderingMode(.original)
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
    
    var pollutionChart: some View {
        PollutionChart()
            .frame(height: 200)
    }
}

struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        SessionCell()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
