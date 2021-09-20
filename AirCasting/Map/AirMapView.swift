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
    var thresholds: [SensorThreshold]
    @StateObject var statsContainerViewModel: StatisticsContainerViewModel
    @StateObject var mapStatsDataSource: MapStatsDataSource
    @ObservedObject var session: SessionEntity
    @Binding var showLoadingIndicator: Bool

    @Binding var selectedStream: MeasurementStreamEntity?
    let sessionStoppableFactory: SessionStoppableFactory
    let measurementStreamStorage: MeasurementStreamStorage
    
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
                              isExpandButtonNeeded: false, isCollapsed: Binding.constant(false),
                              session: session,
                              sessionStopperFactory: sessionStoppableFactory)
            ABMeasurementsView(viewModelProvider: { DefaultSyncingMeasurementsViewModel(measurementStreamStorage: measurementStreamStorage,
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

            if let threshold = thresholds.threshold(for: selectedStream) {
                if !showLoadingIndicator {
                    ZStack(alignment: .topLeading) {
                        GoogleMapView(pathPoints: pathPoints,
                                      threshold: threshold)
                            .onPositionChange { [weak mapStatsDataSource, weak statsContainerViewModel] visiblePoints in
                                mapStatsDataSource?.visiblePathPoints = visiblePoints
                                statsContainerViewModel?.adjustForNewData()
                            }
                    StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                            threshold: threshold)     
                    }
                    NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: threshold.rawThresholdsBinding)) {
                        EditButtonView()
                    }
                    ThresholdsSliderView(threshold: threshold)
                        // Fixes labels covered by tabbar
                        .padding(.bottom)
                } else {
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

#if DEBUG
struct Map_Previews: PreviewProvider {
    static var previews: some View {
        AirMapView(thresholds: [SensorThreshold.mock],
                   statsContainerViewModel: StatisticsContainerViewModel(statsInput: MeasurementsStatisticsInputMock()),
                   mapStatsDataSource: MapStatsDataSource(),
                   session: .mock,
                   showLoadingIndicator: .constant(true),
                   selectedStream: .constant(nil),
                   sessionStoppableFactory: SessionStoppableFactoryDummy(),
                   measurementStreamStorage: PreviewMeasurementStreamStorage())
    }
}

struct MeasurementsStatisticsInputMock: MeasurementsStatisticsInput {
    func computeStatistics() { }
}
#endif
