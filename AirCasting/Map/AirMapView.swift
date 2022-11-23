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
import Resolver

class HeatmapContainer: ObservableObject {
    var heatMap: Heatmap?
}

struct AirMapView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @InjectedObject private var userSettings: UserSettings
    @ObservedObject var thresholds: ABMeasurementsViewThreshold
    @StateObject var statsContainerViewModel: StatisticsContainerViewModel
    @StateObject var mapNotesVM: MapNotesViewModel
//  @StateObject var mapStatsDataSource: MapStatsDataSource
    @ObservedObject var session: SessionEntity
    @Binding var showLoadingIndicator: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    @State var currentlyPresentedNoteDetails: MapNote? = nil // If set to nil, hide modal, if not nil show modal
    @Injected private var locationTracker: LocationTracker
    
    @StateObject private var heatmapContainer = HeatmapContainer()
    
    init(session: SessionEntity,
         thresholds: ABMeasurementsViewThreshold,
         statsContainerViewModel: StateObject<StatisticsContainerViewModel>,
         showLoadingIndicator: Binding<Bool>,
         selectedStream: Binding<MeasurementStreamEntity?>) {
        self.session = session
        self.thresholds = thresholds
        self._statsContainerViewModel = statsContainerViewModel
        self._mapNotesVM = .init(wrappedValue: .init(sessionUUID: session.uuid))
        self._showLoadingIndicator = showLoadingIndicator
        self._selectedStream = selectedStream
    }
    
    private var pathPoints: [_MapView.PathPoint] {
        return selectedStream?.allMeasurements?.compactMap {
            guard let location = $0.location else { return nil }
            return .init(lat: location.latitude, long: location.longitude, value: $0.value)
        } ?? []
    }

    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              isSensorTypeNeeded: false,
                              isCollapsed: Binding.constant(false),
                              session: session)
            .padding([.bottom, .leading, .trailing])
            
            ABMeasurementsView(session: session,
                               isCollapsed: Binding.constant(false),
                               selectedStream: $selectedStream,
                               thresholds: thresholds,
                               measurementPresentationStyle: .showValues,
                               viewModel:  DefaultSyncingMeasurementsViewModel(sessionDownloader: SessionDownloadService(),
                                                                               session: session))
            .padding([.bottom, .leading, .trailing])
            
            if let threshold = thresholds.value.threshold(for: selectedStream?.sensorName ?? "") {
                if !showLoadingIndicator {
                    ZStack(alignment: .topLeading) {
                        if session.isFixed {
                            // Kropka customowa
                            // brak PathPoint - nie rysujemy ścieżki
                            _MapView(path: pathPoints,
                                     type: .normal,
                                     trackingStyle: .latestPathPoint,
                                     userIndicatorStyle: .custom(color: _MapViewThresholdFormatter.shared.color(points: pathPoints, threshold: threshold)),
                                     userTracker: ConstantTracker(location: pathPoints.last?.location ?? .apple))

                        } else if session.isActive {
                            // Kropka customowa
                            // są pointy - rysujemy drogę
                            // aktualizacje trasy live
                            _MapView(path: pathPoints,
                                     type: .normal,
                                     trackingStyle: .latestPathPoint,
                                     userIndicatorStyle: .custom(color: _MapViewThresholdFormatter.shared.color(points: pathPoints, threshold: threshold)),
                                     userTracker: UserTrackerAdapter(locationTracker),
                                     markers: mapNotesVM.notes.asMapMarkers(with: didTapNote))
                        } else {
                            // kropka customowa
                            // rusyjemy raz już gotową trasę
                            // nie ma potrzeby aktualizacji
                            _MapView(path: pathPoints,
                                     type: .normal,
                                     trackingStyle: .wholePath,
                                     userIndicatorStyle: .none,
                                     userTracker: UserTrackerAdapter(locationTracker),
                                     markers: mapNotesVM.notes.asMapMarkers(with: didTapNote))
                            .addingOverlay { mapView in
                                Log.verbose("## Drawing heatmap")
                                heatmapContainer.heatMap?.remove()
                                let mapWidth = mapView.frame.width
                                let mapHeight = mapView.frame.height
                                guard mapWidth > 0, mapHeight > 0 else { return }
                                heatmapContainer.heatMap = Heatmap(mapView, sensorThreshold: threshold, mapWidth: Int(mapWidth), mapHeight: Int(mapHeight))
                                heatmapContainer.heatMap?.drawHeatMap(pathPoints: pathPoints.map { .init(location: .init(latitude: $0.lat, longitude: $0.long), measurementTime: DateBuilder.distantPast(), measurement: $0.value) })
                            }
                        }
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
                    
                    if let selectedStream = selectedStream, let formatter = Resolver.resolve(ThresholdFormatter.self, args: threshold) {
                        NavigationLink(destination: ThresholdsSettingsView(thresholdValues: formatter.formattedBinding(),
                                                                           initialThresholds: selectedStream.thresholds,
                                                                           threshold: threshold)) {
                            EditButtonView()
                        }.padding([.bottom, .leading, .trailing])
                    }
                    ThresholdsSliderView(threshold: threshold)
                    // Fixes labels covered by tabbar
                        .padding([.bottom, .leading, .trailing])
                }
            }
            Spacer()
        }
        .sheet(item: $currentlyPresentedNoteDetails, content: { note in
            EditNoteView(viewModel: EditNoteViewModelDefault(exitRoute: { currentlyPresentedNoteDetails = nil },
                                                             noteNumber: note.id,
                                                             sessionUUID: session.uuid))
        })
        .navigationBarTitleDisplayMode(.inline)
        //        .onChange(of: selectedStream) { newStream in
        //            mapStatsDataSource.visiblePathPoints = pathPoints
        //            statsContainerViewModel.adjustForNewData()
        //        }
        .onAppear { statsContainerViewModel.adjustForNewData() }
        .padding(.bottom)
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
    
    private func getValue(of measurement: MeasurementEntity) -> Double {
        measurement.measurementStream.isTemperature && userSettings.convertToCelsius ? TemperatureConverter.calculateCelsius(fahrenheit: measurement.value) : measurement.value
    }
    
    private func didTapNote(_ note: MapNote) {
        currentlyPresentedNoteDetails = note
    }
}

fileprivate extension Array where Element == MapNote {
    func asMapMarkers(with handler: @escaping (MapNote) -> Void) -> [_MapView.Marker] {
        map { note in .init(id: note.id,
                            image: note.markerImage,
                            location: CLLocation(latitude: note.location.latitude, longitude: note.location.longitude),
                            handler: { handler(note) } )}
    }
}

extension _MapView.PathPoint {
    var location: CLLocation {
        .init(latitude: lat, longitude: long)
    }
}
