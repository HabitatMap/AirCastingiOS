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
    // It keeps track of heatmap instances
    // so that we always have only one
    var heatMap: Heatmap?
}

struct AirMapView: View {
    @Environment(\.scenePhase) var scenePhase

    @InjectedObject private var userSettings: UserSettings
    @ObservedObject var thresholds: ABMeasurementsViewThreshold
    @StateObject var statsContainerViewModel: StatisticsContainerViewModel
    @StateObject var mapNotesVM: MapNotesViewModel
    @ObservedObject var session: SessionEntity
    @Binding var showLoadingIndicator: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    @State var currentlyPresentedNoteDetails: MapNote? = nil // If set to nil, hide modal, if not nil show modal
    @Injected private var locationTracker: LocationTracker
    
    @StateObject private var heatmapContainer = HeatmapContainer()

    enum AirMapSessionType {
        case fixed
        case active
        case other
    }
    
    var mapSessionType: Self.AirMapSessionType {
        if session.isActive {
            return .active
        } else if session.isFixed {
            return .fixed
        } else {
            return .other
        }
    }
    
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
                        switch mapSessionType {
                        case .active:
                            // - custom dot
                            // - draw path when ongoing session updates
                            // - live tracking
                            _MapView(path: pathPoints,
                                     type: .normal,
                                     trackingStyle: .latestPathPoint,
                                     userIndicatorStyle: .custom(color: _MapViewThresholdFormatter.shared.color(points: pathPoints, threshold: threshold)),
                                     userTracker: UserTrackerAdapter(locationTracker),
                                     markers: mapNotesVM.notes.asMapMarkers(with: didTapNote))
                            .addingOverlay { mapView in
                                heatmapContainer.heatMap?.remove()
                                let mapWidth = mapView.frame.width
                                let mapHeight = mapView.frame.height
                                guard mapWidth > 0, mapHeight > 0 else { return }
                                heatmapContainer.heatMap = Heatmap(mapView, sensorThreshold: threshold, mapWidth: Int(mapWidth), mapHeight: Int(mapHeight))
                                heatmapContainer.heatMap?.drawHeatMap(pathPoints: pathPoints.map { .init(location: .init(latitude: $0.lat,
                                                                                                                         longitude: $0.long),
                                                                                                         measurementTime: DateBuilder.distantPast(),
                                                                                                         measurement: $0.value) })
                            }
                        case .fixed:
                            // - custom dot
                            // - no path drawing
                            _MapView(path: pathPoints,
                                     type: .normal,
                                     trackingStyle: .latestPathPoint,
                                     userIndicatorStyle: .custom(color: _MapViewThresholdFormatter.shared.color(points: pathPoints, threshold: threshold)),
                                     userTracker: ConstantTracker(location: pathPoints.last?.location ?? .applePark))
                        case .other:
                            // here only mobileDormant type should be considered
                            // - custom dot
                            // - draw already known and finished path
                            // - no need for real time updated
                            _MapView(path: pathPoints,
                                     type: .normal,
                                     trackingStyle: .wholePath,
                                     userIndicatorStyle: .none,
                                     userTracker: UserTrackerAdapter(locationTracker),
                                     markers: mapNotesVM.notes.asMapMarkers(with: didTapNote))
                            .addingOverlay { mapView in
                                heatmapContainer.heatMap?.remove()
                                let mapWidth = mapView.frame.width
                                let mapHeight = mapView.frame.height
                                guard mapWidth > 0, mapHeight > 0 else { return }
                                heatmapContainer.heatMap = Heatmap(mapView, sensorThreshold: threshold, mapWidth: Int(mapWidth), mapHeight: Int(mapHeight))
                                heatmapContainer.heatMap?.drawHeatMap(pathPoints: pathPoints.map { .init(location: .init(latitude: $0.lat,
                                                                                                                         longitude: $0.long),
                                                                                                         measurementTime: DateBuilder.distantPast(),
                                                                                                         measurement: $0.value) })
                            }
                        }
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
        .onAppear {
            statsContainerViewModel.adjustForNewData()
            statsContainerViewModel.continuousModeEnabled = true
        }
        .onDisappear {
            statsContainerViewModel.continuousModeEnabled = false
        }
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
