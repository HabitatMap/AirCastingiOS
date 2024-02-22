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
    @State private var showThresholdsMenu = false
    
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
                             locationTracker: ConstantTracker(location: pathPoints.last?.location ?? .applePark))
                    StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                            threshold: threshold)
                }.padding(.bottom)
                if let selectedStream = selectedStream {
                    let formatter = Resolver.resolve(ThresholdFormatter.self, args: threshold)
                    Button(action: { showThresholdsMenu = true  }, label: {
                        EditButtonView()
                            .padding([.bottom, .leading, .trailing])
                    })
                    .sheet(isPresented: $showThresholdsMenu) {
                        ThresholdsSettingsView(thresholdValues: formatter.formattedBinding(),
                                                                           initialThresholds: selectedStream.thresholds,
                                                                           threshold: threshold)
                    }
                }
                ThresholdsSliderView(threshold: threshold)
                // Fixes labels covered by tabbar
                    .padding([.bottom, .leading, .trailing])
            }
            Spacer()
        }
        .onAppear {
            statsContainerViewModel.adjustForNewData()
            statsContainerViewModel.continuousModeEnabled = true
        }
        .onDisappear {
            statsContainerViewModel.continuousModeEnabled = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .padding(.bottom)
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
    
    private func getValue(of measurement: MeasurementEntity) -> Double {
        measurement.measurementStream.isTemperature && userSettings.convertToCelsius ? TemperatureConverter.calculateCelsius(fahrenheit: measurement.value) : measurement.value
    }
}
