//
//  CalculatedMeasurements.swift
//  AirCasting
//
//  Created by Lunar on 18/01/2021.
//

import SwiftUI

struct StatisticsContainerView<ViewModelType>: View where ViewModelType: StatisticsContainerViewModelable {
    @ObservedObject var statsContainerViewModel: ViewModelType
    @ObservedObject var threshold: SensorThreshold
    
    var body: some View {
        HStack {
            ForEach(statsContainerViewModel.stats) { stat in
                VStack(spacing: 7) {
                    Text(stat.title)
                    if stat.presentationStyle == .distinct {
                        distinctParameter(value: stat.value)
                    } else if stat.presentationStyle == .standard {
                        standardParameter(value: stat.value)
                    }
                }
            }
        }
        .font(Fonts.muliHeading5)
        .foregroundColor(.aircastingGray)
        .frame(width: 220, height: 80)
        .background(Color.white)
        .cornerRadius(8)
        .padding(.leading, 10)
        .padding(.top, 10)
    }
    
    private func standardParameter(value: Double) -> some View {
        ZStack {
            threshold.colorFor(value: Int32(value))
                .opacity(0.32)
                .cornerRadius(7.5)
            HStack {
                Spacer()
                threshold.colorFor(value: Int32(value))
                    .clipShape(Circle())
                    .frame(width: 6, height: 6)
                Spacer()
                Text("\(Int(value))")
                    .font(Fonts.muliHeading5)
                    .minimumScaleFactor(0.1)
                Spacer()
            }
        }.frame(width: 54, height: 27, alignment: .center)
    }
    
    private func distinctParameter(value: Double) -> some View {
        ZStack {
            threshold.colorFor(value: Int32(value))
                .opacity(0.32)
                .cornerRadius(7.5)
            HStack {
                Spacer()
                threshold.colorFor(value: Int32(value))
                    .clipShape(Circle())
                    .frame(width: 8, height: 8)
                Spacer()
                Text("\(Int(value))")
                    .font(Fonts.muliHeading1)
                    .minimumScaleFactor(0.1)
                Spacer()
            }
        }.frame(width: 68, height: 33, alignment: .center)
    }
    
}

#if DEBUG
struct CalculatedMeasurements_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsContainerView(statsContainerViewModel: FakeStatsViewModel(),
                                threshold:  SensorThreshold.mock)
            .previewLayout(.sizeThatFits)
    }
}

class FakeStatsViewModel: StatisticsContainerViewModelable {
    @Published var stats: [SingleStatViewModel] = [
        .init(id: 0, title: "Low dB", value: -40.0, presentationStyle: .standard),
        .init(id: 1, title: "Now dB", value: -10.2, presentationStyle: .distinct),
        .init(id: 2, title: "Peak dB", value: 12.5, presentationStyle: .standard),
    ]

    func adjustForNewData() { }
}
#endif
