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

struct AirMapView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @InjectedObject private var userSettings: UserSettings
    @ObservedObject var thresholds: ABMeasurementsViewThreshold
    @StateObject var statsContainerViewModel: StatisticsContainerViewModel
    @StateObject var mapNotesVM: MapNotesViewModel
    @ObservedObject var session: SessionEntity
    @Binding var showLoadingIndicator: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    @State var isUserInteracting = true
    @State var noteMarkerTapped = false
    @State var noteNumber = 0
    
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
    
    private var pathPoints: [PathPoint] {
        return selectedStream?.allMeasurements?.compactMap {
            guard let location = $0.location else { return nil }
            return PathPoint(location: location, measurementTime: $0.time, measurement: round(getValue(of: $0)))
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
                        GoogleMapView(pathPoints: pathPoints,
                                      threshold: threshold,
                                      placePickerIsUpdating: Binding.constant(false),
                                      isUserInteracting: $isUserInteracting,
                                      isSessionActive: session.isActive,
                                      isSessionFixed: session.isFixed,
                                      noteMarketTapped: $noteMarkerTapped,
                                      noteNumber: $noteNumber,
                                      mapNotes: $mapNotesVM.notes)
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
        .sheet(isPresented: $noteMarkerTapped, content: {
            EditNoteView(viewModel: EditNoteViewModelDefault(exitRoute: { noteMarkerTapped.toggle() },
                                                             noteNumber: noteNumber,
                                                             sessionUUID: session.uuid))
        })
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { statsContainerViewModel.adjustForNewData() }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background, .inactive: isUserInteracting = false
            case .active: isUserInteracting = true
            @unknown default: fatalError()
            }
        }
        .padding(.bottom)
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
    
    private func getValue(of measurement: MeasurementEntity) -> Double {
        measurement.measurementStream.isTemperature && userSettings.convertToCelsius ? TemperatureConverter.calculateCelsius(fahrenheit: measurement.value) : measurement.value
    }
}
