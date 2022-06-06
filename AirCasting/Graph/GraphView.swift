//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI
import Resolver

struct GraphView<StatsViewModelType>: View where StatsViewModelType: StatisticsContainerViewModelable {
    
    let session: SessionEntity
    let thresholds: [SensorThreshold]
    // This pair doesn't belong here, it should be elegantly handled by VM when refactored
    @State private var selectedNote: Note?
    @State private var showNoteEdit: Bool = false
    @Binding var selectedStream: MeasurementStreamEntity?
    @StateObject var statsContainerViewModel: StatsViewModelType
    let graphStatsDataSource: GraphStatsDataSource
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              isSensorTypeNeeded: false,
                              isCollapsed: Binding.constant(false),
                              session: session)
            .padding([.bottom, .leading, .trailing])
            
            ABMeasurementsView(
                session: session,
                isCollapsed: Binding.constant(false),
                selectedStream: $selectedStream,
                thresholds: .init(value: thresholds),
                measurementPresentationStyle: .showValues,
                viewModel: DefaultSyncingMeasurementsViewModel(sessionDownloader: SessionDownloadService(),
                                                               session: session))
            .padding(.horizontal)
            
            if isProceeding(session: session) {
                if let threshold = thresholds.threshold(for: selectedStream?.sensorName ?? "") {
                    let formatter = Resolver.resolve(ThresholdFormatter.self, args: threshold)
                    if let selectedStream = selectedStream {
                        ZStack(alignment: .topLeading) {
                            Graph(stream: selectedStream,
                                  thresholds: threshold,
                                  isAutozoomEnabled: session.type == .mobile)
                            .onDateRangeChange { [weak graphStatsDataSource, weak statsContainerViewModel] range in
                                graphStatsDataSource?.dateRange = range
                                statsContainerViewModel?.adjustForNewData()
                            }
                            .onNoteTap { note in
                                selectedNote = note
                                showNoteEdit = true
                            }
                            // Statistics container shouldn't be presented in mobile dormant tab
                            if !session.isDormant {
                                StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                                        threshold: threshold)
                            }
                        }
                        NavigationLink(destination: ThresholdsSettingsView(thresholdValues: formatter.formattedBinding(),
                                                                           initialThresholds: selectedStream.thresholds,
                                                                           threshold: threshold)) {
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
        .sheet(isPresented: $showNoteEdit, content: { [selectedNote] in
            EditNoteView(viewModel: EditNoteViewModelDefault(exitRoute: { showNoteEdit.toggle() },
                                                             noteNumber: selectedNote!.number,
                                                             sessionUUID: session.uuid))
        })
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func isProceeding(session: SessionEntity) -> Bool {
        return session.allStreams.allSatisfy({ stream in
            !(stream.allMeasurements?.isEmpty ?? true)
        }) ?? false
    }
}
