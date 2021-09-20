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
        .font(Font.muli(size: 12))
        .foregroundColor(.aircastingGray)
        .frame(width: 260, height: 85)
        .background(Color.white)
        .cornerRadius(8)
        .padding()
    }
    
    private func standardParameter(value: Double) -> some View {
        ZStack {
            threshold.colorFor(value: Int32(value))
                .opacity(0.32)
                .cornerRadius(7.5)
            HStack {
                threshold.colorFor(value: Int32(value))
                    .clipShape(Circle())
                    .frame(width: 6, height: 6)
                    .padding(.leading, 3)
                Spacer()
                Text("\(Int(value))")
                    .padding(.trailing, 3)
                    .font(Font.muli(size: 12))
                    .minimumScaleFactor(0.1)
            }
        }.frame(width: 54, height: 27, alignment: .center)
    }
    
    private func distinctParameter(value: Double) -> some View {
        ZStack {
            threshold.colorFor(value: Int32(value))
                .opacity(0.32)
                .cornerRadius(7.5)
            HStack {
                threshold.colorFor(value: Int32(value))
                    .clipShape(Circle())
                    .frame(width: 8, height: 8)
                    .padding(.leading, 5)
                Spacer()
                Text("\(Int(value))")
                    .padding(.trailing, 5)
                    .font(Font.muli(size: 19))
                    .minimumScaleFactor(0.1)
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
