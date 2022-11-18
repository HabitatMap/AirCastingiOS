// Created by Lunar on 13/05/2022.
//

import SwiftUI
import Resolver

struct ExternalSessionMapView: View {
    @InjectedObject private var userSettings: UserSettings
    @ObservedObject var session: ExternalSessionEntity
    @ObservedObject var thresholds: ABMeasurementsViewThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    @StateObject var statsContainerViewModel: StatisticsContainerViewModel
    @Injected private var locationTracker: LocationTracker
    
    private var pathPoints: [_MapView.PathPoint] {
        return selectedStream?.allMeasurements?.compactMap {
            guard let location = $0.location else { return nil }
            return .init(lat: location.latitude, long: location.longitude, value: $0.value)
        } ?? []
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            ExternalSessionHeader(session: session, thresholds: thresholds, selectedStream: $selectedStream, isCollapsed: .constant(false), expandingAction: nil)
                .padding([.bottom, .leading, .trailing])
            if let threshold = thresholds.value.threshold(for: selectedStream?.sensorName ?? "") {
                ZStack(alignment: .topLeading) {
                    _MapView(path: pathPoints,
                             type: .normal,
                             trackingStyle: .latestPathPoint,
                             userIndicatorStyle: .custom(color: _MapViewThresholdFormatter.shared.color(points: pathPoints, threshold: threshold)),
                             userTracker: UserTrackerAdapter(locationTracker))
//                    GoogleMapView(pathPoints: pathPoints,
//                                  threshold: threshold,
//                                  placePickerIsUpdating: Binding.constant(false),
//                                  isUserInteracting: Binding.constant(true),
//                                  isSessionActive: false,
//                                  isSessionFixed: true,
//                                  noteMarketTapped: Binding.constant(false),
//                                  noteNumber: Binding.constant(0),
//                                  mapNotes: Binding.constant([]))
                    StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                            threshold: threshold)
                }.padding(.bottom)
                if let selectedStream = selectedStream {
                    NavigationLink(destination: ThresholdsSettingsView(thresholdValues: threshold.thresholdsBinding,
                                                                       initialThresholds: selectedStream.thresholds, threshold: threshold)) {
                        EditButtonView()
                    }.padding([.bottom, .leading, .trailing])
                }
                ThresholdsSliderView(threshold: threshold)
                // Fixes labels covered by tabbar
                    .padding([.bottom, .leading, .trailing])
            }
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .padding(.bottom)
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
    
    private func getValue(of measurement: MeasurementEntity) -> Double {
        measurement.measurementStream.isTemperature && userSettings.convertToCelsius ? TemperatureConverter.calculateCelsius(fahrenheit: measurement.value) : measurement.value
    }
}
