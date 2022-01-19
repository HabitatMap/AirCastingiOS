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
    // This pair doesn't belong here, it should be elegantly handled by VM when refactored
    @State private var selectedNote: Note?
    @State private var showNoteEdit: Bool = false
    @Binding var selectedStream: MeasurementStreamEntity?
    @StateObject var statsContainerViewModel: StatsViewModelType
    @EnvironmentObject var locationTracker: LocationTracker
    @EnvironmentObject var authorization: UserAuthenticationSession
    let urlProvider: BaseURLProvider
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
                                  urlProvider: urlProvider,
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
                                                                                                         responseValidator: DefaultHTTPResponseValidator(), urlProvider: urlProvider),
                                                                session: session))
                .padding(.horizontal)
           
            if isProceeding(session: session) {
                if let threshold = thresholds.threshold(for: selectedStream) {
                    if let selectedStream = selectedStream {
                        ZStack(alignment: .topLeading) {
                            Graph(stream: selectedStream,
                                  thresholds: threshold,
                                  isAutozoomEnabled: session.type == .mobile,
                                  notesHandler: NotesHandlerDefault(measurementStreamStorage: measurementStreamStorage,
                                                                    sessionUUID: session.uuid,
                                                                    locationTracker: locationTracker,
                                                                    sessionUpdateService: DefaultSessionUpdateService(
                                    authorization: authorization,
                                    urlProvider: urlProvider),
                                                                    persistenceController: PersistenceController.shared))
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
        .sheet(isPresented: $showNoteEdit, content: { [selectedNote] in
            EditNoteView(viewModel: EditNoteViewModelDefault(exitRoute: { showNoteEdit.toggle() },
                                                             noteNumber: selectedNote!.number,
                                                             notesHandler: NotesHandlerDefault(
                                                                measurementStreamStorage: measurementStreamStorage,
                                                                sessionUUID: session.uuid,
                                                                locationTracker: locationTracker,
                                                                sessionUpdateService: DefaultSessionUpdateService(
                                                                    authorization: authorization,
                                                                    urlProvider: urlProvider),
                                                                persistenceController: PersistenceController.shared)))
        })
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func isProceeding(session: SessionEntity) -> Bool {
        return session.allStreams?.allSatisfy({ stream in
            !(stream.allMeasurements?.isEmpty ?? true)
        }) ?? false
    }
}
