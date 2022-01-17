//
//  Map.swift
//  AirCasting
//
//  Created by Lunar on 25/01/2021.
//

import SwiftUI
import CoreLocation
import Foundation
import CoreData

struct AirMapView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var locationTracker: LocationTracker
    @EnvironmentObject var authorization: UserAuthenticationSession
    
    var thresholds: [SensorThreshold]
    let urlProvider: BaseURLProvider
    let sessionStoppableFactory: SessionStoppableFactory
    let measurementStreamStorage: MeasurementStreamStorage
    let sessionSynchronizer: SessionSynchronizer
    
    @StateObject var statsContainerViewModel: StatisticsContainerViewModel
    @StateObject var mapNotesVM: MapNotesViewModel
//  @StateObject var mapStatsDataSource: MapStatsDataSource
    @ObservedObject var session: SessionEntity
    @Binding var showLoadingIndicator: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    @State var isUserInteracting = true
    @State var noteMarkerTapped = false
    @State var noteNumber = 0
    var notesHandler: NotesHandler
    
    init(session: SessionEntity,
         thresholds: [SensorThreshold],
         urlProvider: BaseURLProvider,
         sessionStoppableFactory: SessionStoppableFactory,
         measurementStreamStorage: MeasurementStreamStorage,
         sessionSynchronizer: SessionSynchronizer,
         statsContainerViewModel: StateObject<StatisticsContainerViewModel>,
         notesHandler: NotesHandler,
         showLoadingIndicator: Binding<Bool>,
         selectedStream: Binding<MeasurementStreamEntity?>) {
        self.session = session
        self.thresholds = thresholds
        self.urlProvider = urlProvider
        self.sessionStoppableFactory = sessionStoppableFactory
        self.measurementStreamStorage = measurementStreamStorage
        self.sessionSynchronizer = sessionSynchronizer
        self._statsContainerViewModel = statsContainerViewModel
        self.notesHandler = notesHandler
        self._mapNotesVM = .init(wrappedValue: .init(notesHandler: notesHandler))
        self._showLoadingIndicator = showLoadingIndicator
        self._selectedStream = selectedStream
    }
    
    private var pathPoints: [PathPoint] {
        return selectedStream?.allMeasurements?.compactMap {
            #warning("TODO: Do something with no location points")
            guard let location = $0.location else { return nil }
            return PathPoint(location: location, measurementTime: $0.time, measurement: $0.value)
        } ?? []
    }

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
            
            ABMeasurementsView(session: session,
                               isCollapsed: Binding.constant(false),
                               selectedStream: $selectedStream,
                               thresholds: thresholds, measurementPresentationStyle: .showValues,
                               viewModel:  DefaultSyncingMeasurementsViewModel(measurementStreamStorage: measurementStreamStorage,
                                                                               sessionDownloader: SessionDownloadService(client: URLSession.shared,
                                                                                                                         authorization: UserAuthenticationSession(), responseValidator: DefaultHTTPResponseValidator(), urlProvider: urlProvider),
                                                                                session: session))
                .padding([.bottom, .leading, .trailing])

            if let threshold = thresholds.threshold(for: selectedStream) {
                if !showLoadingIndicator {
                    ZStack(alignment: .topLeading) {
                        GoogleMapView(pathPoints: pathPoints,
                                      threshold: threshold,
                                      placePickerDismissed: Binding.constant(false),
                                      isUserInteracting: $isUserInteracting,
                                      isSessionActive: session.isActive,
                                      isSessionFixed: session.isFixed,
                                      noteMarketTapped: $noteMarkerTapped,
                                      noteNumber: $noteNumber,
                                      mapNotes: $mapNotesVM.notes)
                        #warning("TODO: Implement calculating stats only for visible path points")
                        // This doesn't work properly and it needs to be fixed, so I'm commenting it out
//                            .onPositionChange { [weak mapStatsDataSource, weak statsContainerViewModel] visiblePoints in
//                                mapStatsDataSource?.visiblePathPoints = visiblePoints
//                                statsContainerViewModel?.adjustForNewData()
//                            }
                        // Statistics container shouldn't be presented in mobile dormant tab
                        if !(session.type == .mobile && session.isActive == false) {
                            StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                                    threshold: threshold)
                        }
                    }.padding(.bottom)
                    
                    if let selectedStream = selectedStream {
                        NavigationLink(destination: ThresholdsSettingsView(thresholdValues: threshold.thresholdsBinding,
                                                                           initialThresholds: selectedStream.thresholds)) {
                            EditButtonView()
                        }.padding([.bottom, .leading, .trailing])
                    }
                    ThresholdsSliderView(threshold: threshold)
                        // Fixes labels covered by tabbar
                        .padding([.bottom, .leading, .trailing])
                } else {
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $noteMarkerTapped, content: {
            EditNoteView(viewModel: EditNoteViewModelDefault(exitRoute: {
                noteMarkerTapped.toggle()
            },
                                                             noteNumber: noteNumber,
                                                             notesHandler: notesHandler, sessionUpdateService: DefaultSessionUpdateService(authorization: authorization, urlProvider: urlProvider)))
        })
        .navigationBarTitleDisplayMode(.inline)
//        .onChange(of: selectedStream) { newStream in
//            mapStatsDataSource.visiblePathPoints = pathPoints
//            statsContainerViewModel.adjustForNewData()
//        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background, .inactive: isUserInteracting = false
            case .active: isUserInteracting = true
            @unknown default: fatalError()
            }
        }
        .padding(.bottom)
    }
}
