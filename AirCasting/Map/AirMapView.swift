//
//  Map.swift
//  AirCasting
//
//  Created by Lunar on 25/01/2021.
//

import SwiftUI
import CoreLocation
import Foundation

struct AirMapView: View {
    
    @Binding var thresholds: [Float]
    let pathPoints: [PathPoint]
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              // TODO: replace mocked session
                              session: Session.mock)
            ZStack(alignment: .topLeading) {
                GoogleMapView(pathPoints: pathPoints, thresholds: thresholds)
                StatisticsContainerView()
            }
            NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: $thresholds)) {
                EditButtonView()
            }
            MultiSliderView(thresholds: $thresholds)
                // Fixes labels covered by tabbar
                .padding(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

struct Map_Previews: PreviewProvider {
    static var previews: some View {
        AirMapView(thresholds: .constant([0,1,2,3,10]),
                   pathPoints: [PathPoint(location: CLLocationCoordinate2D(latitude: 40.73,
                                                                           longitude: -73.93),
                   measurement: 10),
                   PathPoint(location: CLLocationCoordinate2D(latitude: 40.83,
                                                              longitude: -73.93),
                   measurement: 50),
                   PathPoint(location: CLLocationCoordinate2D(latitude: 40.93,
                                                              longitude: -73.83),
                   measurement: 80)])
    }
}
