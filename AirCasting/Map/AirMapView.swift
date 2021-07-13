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
    var threshold: SensorThreshold
    @ObservedObject var session: SessionEntity
    @Binding var selectedStream: MeasurementStreamEntity?
    
    private var pathPoints: [PathPoint] {
        return selectedStream?.allMeasurements?.compactMap {
            #warning("TODO: Do something with no location points")
            guard let location = $0.location else { return nil }
            return PathPoint(location: location, measurement: $0.value)
        } ?? []
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              session: session,
                              threshold: threshold,
                              selectedStream: $selectedStream)
            ZStack(alignment: .topLeading) {
                GoogleMapView(pathPoints: pathPoints,
                              thresholds: threshold)
                StatisticsContainerView()
            }
            NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: threshold.rawThresholdsBinding)) {
                EditButtonView()
            }
            ThresholdsSliderView(threshold: threshold)
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
        AirMapView(threshold: .mock, session: .mock, selectedStream: .constant(nil))
    }
}
#endif
