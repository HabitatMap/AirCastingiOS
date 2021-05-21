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
    @ObservedObject var session: SessionEntity

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
                return PathPoint(location: location, measurement: $0.value)
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
                              thresholds: [.mock])
            ZStack(alignment: .topLeading) {
                GoogleMapView(pathPoints: pathPoints,
                              thresholds: thresholds[0])
                StatisticsContainerView()
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
        AirMapView(thresholds: [SensorThreshold.mock], session: .mock)
    }
}
#endif
