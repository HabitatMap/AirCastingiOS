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
    
    var thresholds: [SensorThreshold]
    @StateObject var statsContainerViewModel: StatisticsContainerViewModel
//    @StateObject var mapStatsDataSource: MapStatsDataSource
    @ObservedObject var session: SessionEntity
    @Binding var showLoadingIndicator: Bool
    @State var isUserInteracting = true
    @State var noteMarkerTapped = false
    @State var noteNumber = 0
    @Binding var selectedStream: MeasurementStreamEntity?
    let urlProvider: BaseURLProvider
    let sessionStoppableFactory: SessionStoppableFactory
    let measurementStreamStorage: MeasurementStreamStorage
    let sessionSynchronizer: SessionSynchronizer
    
    private var pathPoints: [PathPoint] {
        return selectedStream?.allMeasurements?.compactMap {
            #warning("TODO: Do something with no location points")
            guard let location = $0.location else { return nil }
            return PathPoint(location: location, measurementTime: $0.time, measurement: $0.value)
        } ?? []
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
                SessionHeaderView(action: {},
                                  isExpandButtonNeeded: false,
                                  isSensorTypeNeeded: false,
                                  isCollapsed: Binding.constant(false),
                                  urlProvider: urlProvider,
                                  session: session,
                                  sessionStopperFactory: sessionStoppableFactory,
                                  measurementStreamStorage: measurementStreamStorage,
                                  sessionSynchronizer: sessionSynchronizer)
            
            ABMeasurementsView(session: session,
                               isCollapsed: Binding.constant(false),
                               selectedStream: $selectedStream,
                               thresholds: thresholds, measurementPresentationStyle: .showValues,
                               viewModel:  DefaultSyncingMeasurementsViewModel(measurementStreamStorage: measurementStreamStorage,
                                                                               sessionDownloader: SessionDownloadService(client: URLSession.shared,
                                                                                                                         authorization: UserAuthenticationSession(), responseValidator: DefaultHTTPResponseValidator(), urlProvider: urlProvider),
                                                                                session: session))

            if let threshold = thresholds.threshold(for: selectedStream) {
                if !showLoadingIndicator {
                    ZStack(alignment: .topLeading) {
                        GoogleMapView(pathPoints: pathPoints,
                                      threshold: threshold,
                                      placePickerDismissed: Binding.constant(false),
                                      isUserInteracting: $isUserInteracting,
                                      isSessionActive: session.isActive,
                                      isSessionFixed: session.isFixed,
                                      notes: NotesHandlerDefault(measurementStreamStorage: measurementStreamStorage,
                                                                 session: session).getNotesFromDatabase(),
                                      noteMarketTapped: $noteMarkerTapped,
                                      noteNumber: $noteNumber)
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
                    }
                    if let selectedStream = selectedStream {
                        NavigationLink(destination: ThresholdsSettingsView(thresholdValues: threshold.thresholdsBinding,
                                                                           initialThresholds: selectedStream.thresholds)) {
                            EditButtonView()
                        }
                    }
                    ThresholdsSliderView(threshold: threshold)
                        // Fixes labels covered by tabbar
                        .padding(.bottom)
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
                                                             notesHandler: NotesHandlerDefault(measurementStreamStorage: measurementStreamStorage,
                                                                         session: session)))
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
        .padding([.bottom, .leading, .trailing])
    }
}

#if DEBUG
struct Map_Previews: PreviewProvider {
    static var previews: some View {
        AirMapView(thresholds: [SensorThreshold.mock],
                   statsContainerViewModel: StatisticsContainerViewModel(statsInput: MeasurementsStatisticsInputMock()),
//                   mapStatsDataSource: MapStatsDataSource(),
                   session: .mock,
                   showLoadingIndicator: .constant(true),
                   selectedStream: .constant(nil),
                   urlProvider: DummyURLProvider(),
                   sessionStoppableFactory: SessionStoppableFactoryDummy(),
                   measurementStreamStorage: PreviewMeasurementStreamStorage(),
                   sessionSynchronizer: DummySessionSynchronizer())
    }
}

struct MeasurementsStatisticsInputMock: MeasurementsStatisticsInput {
    func computeStatistics() { }
}
#endif
