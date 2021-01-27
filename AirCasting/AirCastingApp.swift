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
    
    var pathPoints: [PathPoint] {
        let allLocationPoints = provider.allLocations
        let points = allLocationPoints.map { (location) in
            PathPoint(location: location.coordinate,
                      measurement: Float(arc4random() % 100))
        }
        return points
    }
    
    var body: some Scene {
            WindowGroup {
                NavigationView {
//                    GraphView()
//                    Dashboard()
//                    SessionCell()
                    GoogleMapView(pathPoints: pathPoints)
            }
        }
    }
}
