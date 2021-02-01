//
//  CalculatedMeasurements.swift
//  AirCasting
//
//  Created by Lunar on 18/01/2021.
//

import SwiftUI

struct StatisticsContainer: View {
    var body: some View {
        HStack {
            avgLabel
            nowLabel
            peakLabel
        }
        .font(Font.muli(size: 12))
        .foregroundColor(.aircastingGray)
        .frame(width: 260, height: 85)
        .background(Color.white)
        .cornerRadius(8)
        .padding()
    }
    
    var avgLabel: some View {
        VStack(spacing: 7) {
            Text("Avg PM2.5")
            parameter
        }
    }
    
    var peakLabel: some View {
        VStack(spacing: 7) {
            Text("Peak PM2.5")
            parameter
        }
    }
    
    var nowLabel: some View {
        VStack(spacing: 7) {
            Text("Now PM2.5")
            nowParameter
        }
    }
    
    var parameter: some View {
        ZStack {
            Color.aircastingGreen
                .opacity(0.32)
                .frame(width: 54, height: 27, alignment: .center)
                .cornerRadius(7.5)
            HStack(spacing: 16) {
                Color.aircastingGreen
                    .clipShape(Circle())
                    .frame(width: 6, height: 6)
                Text("23")
            }
        }
    }
    var nowParameter: some View {
        ZStack {
            Color.aircastingGreen
                .opacity(0.32)
                .frame(width: 68, height: 33, alignment: .center)
                .cornerRadius(7.5)
            HStack(spacing: 16) {
                Color.aircastingGreen
                    .clipShape(Circle())
                    .frame(width: 8, height: 8)
                Text("2")
            }
            .font(Font.muli(size: 19))
        }
    }
    
}

struct CalculatedMeasurements_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsContainer()
    }
}
