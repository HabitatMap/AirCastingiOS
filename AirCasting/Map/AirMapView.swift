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
    
    @Binding var values: [Float]
    let pathPoints: [PathPoint]
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              // TODO: replace mocked session
                              session: Session.mock)
            ZStack(alignment: .topLeading) {
                GoogleMapView(pathPoints: pathPoints, values: values)
                StatisticsContainerView()
            }
            NavigationLink(destination: HeatmapSettingsView(changedValues: $values)) {
                EditButton()
            }
            MultiSliderView(values: $values)
                // Fixes labels covered by tabbar
                .padding(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

struct Map_Previews: PreviewProvider {
    static var previews: some View {
        AirMapView(values: .constant([0,1,2,3,10]),
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
