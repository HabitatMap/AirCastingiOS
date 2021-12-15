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
    let sessionSynchronizer: SessionSynchronizer
    
    var body: some View {
        VStack(alignment: .trailing) {
                SessionHeaderView(action: {},
                                  isExpandButtonNeeded: false,
                                  isSensorTypeNeeded: false,
                                  isCollapsed: Binding.constant(false),
                                  session: session,
                                  sessionStopperFactory: sessionStoppableFactory,
                                  measurementStreamStorage: measurementStreamStorage,
                                  sessionSynchronizer: sessionSynchronizer)
                .padding([.bottom, .leading, .trailing])
            
            ABMeasurementsView(
                session: session,
                isCollapsed: Binding.constant(false),
                selectedStream: $selectedStream,
                thresholds: thresholds, measurementPresentationStyle: .showValues,
                viewModel: DefaultSyncingMeasurementsViewModel(measurementStreamStorage: measurementStreamStorage,
                                                               sessionDownloader: SessionDownloadService(client: URLSession.shared,
                                                                authorization: UserAuthenticationSession(),
                                                                responseValidator: DefaultHTTPResponseValidator()),
                                                                session: session))
                .padding(.horizontal)
           
            if isProceeding(session: session) {
                if let threshold = thresholds.threshold(for: selectedStream) {
                    if let selectedStream = selectedStream {
                        ZStack(alignment: .topLeading) {
                            Graph(stream: selectedStream,
                                  thresholds: threshold,
                                  isAutozoomEnabled: session.type == .mobile).onDateRangeChange { [weak graphStatsDataSource, weak statsContainerViewModel] range in
                                graphStatsDataSource?.dateRange = range
                                statsContainerViewModel?.adjustForNewData()
                            }
                            // Statistics container shouldn't be presented in mobile dormant tab
                            if !session.isDormant {
                                StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                                        threshold: threshold)
                            }
                        }
                        NavigationLink(destination: ThresholdsSettingsView(thresholdValues: threshold.thresholdsBinding,
                                                                           initialThresholds: selectedStream.thresholds)) {
                            EditButtonView()
                                .padding([.horizontal, .top])
                        }
                    }

                    
                    ThresholdsSliderView(threshold: threshold)
                        .padding()
                    // Fixes labels covered by tabbar
                        .padding(.bottom)
                }
            }
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func isProceeding(session: SessionEntity) -> Bool {
        return session.allStreams?.allSatisfy({ stream in
            !(stream.allMeasurements?.isEmpty ?? true)
        }) ?? false
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
                  measurementStreamStorage: PreviewMeasurementStreamStorage(),
                  sessionSynchronizer: DummySessionSynchronizer())
    }
}
#endif
