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
    @Binding var showGraphView: Bool
    @StateObject var statsContainerViewModel: StatsViewModelType
    let graphStatsDataSource: GraphStatsDataSource
    let sessionStoppableFactory: SessionStoppableFactory
    let measurementStreamStorage: MeasurementStreamStorage
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                backButton
                SessionHeaderView(action: {},
                                  isExpandButtonNeeded: false,
                                  isSensorTypeNeeded: false,
                                  isCollapsed: Binding.constant(false),
                                  session: session,
                                  sessionStopperFactory: sessionStoppableFactory).padding()
            }
            
            ABMeasurementsView(viewModelProvider: {
                DefaultSyncingMeasurementsViewModel(measurementStreamStorage: measurementStreamStorage,
                                          sessionDownloader: SessionDownloadService(client: URLSession.shared,
                                                                                    authorization: UserAuthenticationSession(),
                                                                                    responseValidator: DefaultHTTPResponseValidator()),
                                          session: session)
            },
                               session: session,
                               isCollapsed: Binding.constant(false),
                               selectedStream: $selectedStream,
                               thresholds: thresholds,
                               measurementPresentationStyle: .showValues)
                .padding(.horizontal)
           
            if isProceeding(session: session) {
                    if let threshold = thresholds.threshold(for: selectedStream) {
                        ZStack(alignment: .topLeading) {
                            if let selectedStream = selectedStream {
                                Graph(stream: selectedStream,
                                      thresholds: threshold,
                                      isAutozoomEnabled: session.type == .mobile).onDateRangeChange { [weak graphStatsDataSource, weak statsContainerViewModel] range in
                                        graphStatsDataSource?.dateRange = range
                                        statsContainerViewModel?.adjustForNewData()
                                      }
                                // Statistics container shouldn't be presented in mobile dormant tab
                                if !(session.type == .mobile && session.isActive == false) {
                                    StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                                        threshold: threshold)
                                }
                            }
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
    
    var backButton: some View {
        Button {
            showGraphView = false
        } label: {
            Image(systemName: "chevron.backward")
                .foregroundColor(.black)
        }
        .padding(.leading)
    }
}

#if DEBUG
struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(session: .mock,
                  thresholds: [.mock],
                  selectedStream: .constant(nil), showGraphView: .constant(true),
                  statsContainerViewModel: FakeStatsViewModel(),
                  graphStatsDataSource: GraphStatsDataSource(),
                  sessionStoppableFactory: SessionStoppableFactoryDummy(),
                  measurementStreamStorage: PreviewMeasurementStreamStorage())
    }
}
#endif
