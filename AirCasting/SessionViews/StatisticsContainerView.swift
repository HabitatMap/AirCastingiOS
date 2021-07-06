//
//  CalculatedMeasurements.swift
//  AirCasting
//
//  Created by Lunar on 18/01/2021.
//

import SwiftUI

struct StatisticsContainerView: View {
    @ObservedObject var statsContainerViewModel: StatisticsContainerViewModel
    
    var body: some View {
        HStack {
            ForEach(statsContainerViewModel.stats) { stat in
                VStack(spacing: 7) {
                    Text(stat.title)
                    if stat.presentationStyle == .distinct {
                        nowParameter(value: stat.value)
                    } else if stat.presentationStyle == .standard {
                        parameter(value: stat.value)
                    }
                }
            }
        }
        .font(Font.muli(size: 12))
        .foregroundColor(.aircastingGray)
        .frame(width: 260, height: 85)
        .background(Color.white)
        .cornerRadius(8)
        .padding()
    }
    
    func parameter(value: String) -> some View {
        ZStack {
            Color.aircastingGreen
                .opacity(0.32)
                .frame(width: 54, height: 27, alignment: .center)
                .cornerRadius(7.5)
            HStack(spacing: 16) {
                Color.aircastingGreen
                    .clipShape(Circle())
                    .frame(width: 6, height: 6)
                Text(value)
            }
        }
    }
    
    func nowParameter(value: String) -> some View {
        ZStack {
            Color.aircastingGreen
                .opacity(0.32)
                .frame(width: 68, height: 33, alignment: .center)
                .cornerRadius(7.5)
            HStack(spacing: 16) {
                Color.aircastingGreen
                    .clipShape(Circle())
                    .frame(width: 8, height: 8)
                Text(value)
            }
            .font(Font.muli(size: 19))
        }
    }
    
}

#if DEBUG
struct CalculatedMeasurements_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsContainerView(statsContainerViewModel: StatisticsContainerViewModel(statsInput: MeasurementsStatisticsInputMock(), unit: "dB"))
    }
}
#endif
