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
    let statsContainerViewModel: StatisticsContainerViewModel
    let mapStatsDataSource: MapStatsDataSource
    @ObservedObject var session: SessionEntity
    @EnvironmentObject var persistenceController: PersistenceController

    private var measurementStream: MeasurementStreamEntity? {
        if session.type == .mobile && session.deviceType == .MIC {
            return session.dbStream
        } else {
            #warning("Select proper measurementStream")
            return session.measurementStreams?.firstObject as? MeasurementStreamEntity
        }
    }

    private var pathPoints: [PathPoint] {
        measurementStream?.allMeasurements?.compactMap {
            if let location = $0.location {
                return PathPoint(location: location, measurementTime: $0.time, measurement: $0.value)
            } else {
                #warning("TODO: Do something with no location points")
                return nil
            }
       } ?? []
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              session: session,
                              thresholds: thresholds)
            ZStack(alignment: .topLeading) {
                GoogleMapView(pathPoints: pathPoints,
                              thresholds: thresholds[0])
                    .onPositionChange { visiblePoints in
                        mapStatsDataSource.visiblePathPoints = visiblePoints
                        statsContainerViewModel.adjustForNewData()
                    }
                StatisticsContainerView(statsContainerViewModel: statsContainerViewModel)
            }
            NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: thresholds[0].rawThresholdsBinding)) {
                EditButtonView()
            }
            ThresholdsSliderView(threshold: thresholds[0])
                // Fixes labels covered by tabbar
                .padding(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

#if DEBUG
struct Map_Previews: PreviewProvider {
    static var previews: some View {
        AirMapView(thresholds: [SensorThreshold.mock],
                   statsContainerViewModel: StatisticsContainerViewModel(statsInput: MeasurementsStatisticsInputMock(), unit: "dB"),
                   mapStatsDataSource: MapStatsDataSource(stream: .mock),
                   session: .mock)
    }
}

struct MeasurementsStatisticsInputMock: MeasurementsStatisticsInput {
    func visibleDataChanged() { }
}
#endif
