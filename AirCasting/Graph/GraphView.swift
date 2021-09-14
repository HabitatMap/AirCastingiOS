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
    @StateObject var statsContainerViewModel: StatsViewModelType
    let graphStatsDataSource: GraphStatsDataSource
    let sessionStoppableFactory: SessionStoppableFactory
    let measurementStreamStorage: MeasurementStreamStorage
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false, isCollapsed: Binding.constant(false),
                              session: session,
                              sessionStopperFactory: sessionStoppableFactory).padding()

            ABMeasurementsView(session: session,
                               isCollapsed: Binding.constant(false),
                               selectedStream: $selectedStream,
                               showLoadingIndicator: Binding.constant(false),
                               thresholds: thresholds,
                               measurementPresentationStyle: .showValues,
                               measurementStreamStorage: measurementStreamStorage)
                .padding(.horizontal)
            if let threshold = thresholds.threshold(for: selectedStream) {
                ZStack(alignment: .topLeading) {
                    if let selectedStream = selectedStream {
                        Graph(stream: selectedStream,
                              thresholds: threshold,
                              isAutozoomEnabled: session.type == .mobile).onDateRangeChange { [weak graphStatsDataSource, weak statsContainerViewModel] range in
                                graphStatsDataSource?.dateRange = range
                                statsContainerViewModel?.adjustForNewData()
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
                  graphStatsDataSource: GraphStatsDataSource(),
                  sessionStoppableFactory: SessionStoppableFactoryDummy(),
                  measurementStreamStorage: PreviewMeasurementStreamStorage())
    }
}
#endif
