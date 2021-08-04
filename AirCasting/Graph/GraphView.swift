//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct GraphView<StatsViewModelType>: View where StatsViewModelType: StatisticsContainerViewModelable {
    let session: SessionEntity
    let thresholds: [SensorThreshold]
    @Binding var selectedStream: MeasurementStreamEntity?

    let statsContainerViewModel: StatsViewModelType
    let graphStatsDataSource: GraphStatsDataSource
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              session: session).padding()
            StreamsView(selectedStream: $selectedStream,
                        session: session,
                        thresholds: thresholds,
                        measurementPresentationStyle: .showValues)
            if let threshold = thresholds.threshold(for: selectedStream) {
                ZStack(alignment: .topLeading) {
                    if let selectedStream = selectedStream {
                        Graph(stream: selectedStream,
                              thresholds: threshold,
                              isAutozoomEnabled: session.type == .mobile).onDateRangeChange { startDate, endDate in
                                graphStatsDataSource.dateRange = startDate...endDate
                                statsContainerViewModel.adjustForNewData()
                              }
                    }
                    StatisticsContainerView(statsContainerViewModel: statsContainerViewModel)
                }
                NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: threshold.rawThresholdsBinding)) {
                    EditButtonView()
                }
                .padding(.horizontal)
                .padding(.top)
                
                ThresholdsSliderView(threshold: threshold)
                    .padding()
                    // Fixes labels covered by tabbar
                    .padding(.bottom)
            }
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(session: .mock,
                  thresholds: [.mock],
                  selectedStream: .constant(nil),
                  statsContainerViewModel: FakeStatsViewModel(),
                  graphStatsDataSource: GraphStatsDataSource(stream: .mock))
    }
}
#endif
