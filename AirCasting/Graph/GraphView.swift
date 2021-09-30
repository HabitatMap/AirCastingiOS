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
                                StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                                        threshold: threshold)
                            }

                        }
                        HStack() {
                            startTimeText
                            Spacer()
                            endTimeText
                        }
                        .foregroundColor(.aircastingGray)
                        .padding(.horizontal, 5)
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
    
    var startTimeText: some View {
        // Active mobile sessions are being represented in device time, so no UTC reformatting is needed
        // Other sessions are already in the UTC format
        let isActiveMobile = session.isMobile && session.isActive
        let formatter = isActiveMobile ? DateFormatters.GraphView.usLocalTimeDateFormatter : DateFormatters.GraphView.mobileActiveDateFormatter
        
        guard let start = session.startTime else { return Text("") }
        
        let string = formatter.string(from: start)
        return Text(string)
    }
    
    var endTimeText: some View {
        // Active mobile sessions are being represented in device time, so no UTC reformatting is needed
        // Other sessions are already in the UTC format
        let isActiveMobile = session.isMobile && session.isActive
        let formatter = isActiveMobile ? DateFormatters.GraphView.usLocalTimeDateFormatter : DateFormatters.GraphView.mobileActiveDateFormatter
        
        let end = session.endTime ?? Date()
        
        let string = formatter.string(from: end)
        return Text(string)
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
                  measurementStreamStorage: PreviewMeasurementStreamStorage())
    }
}
#endif
