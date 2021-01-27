//
//  AirCastingApp.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import CoreLocation

@main
struct AirCastingApp: App {
    
    @StateObject var provider = LocationTracker()
    
    var body: some Scene {
            WindowGroup {
                NavigationView {
//                    GraphView()
//                    Dashboard()
//                    SessionCell()
                    GoogleMapView(pathPoints: [PathPoint(location: CLLocationCoordinate2D(latitude: 40.73,
                                                                                          longitude: -73.93),
                                                         measurement: 30),
                                               PathPoint(location: CLLocationCoordinate2D(latitude: 40.83,
                                                                                          longitude: -73.93),
                                                         measurement: 30),
                                               PathPoint(location: CLLocationCoordinate2D(latitude: 40.93,
                                                                                          longitude: -73.83),
                                                         measurement: 30)])
            }
        }
    }
}
