//
//  PathPoint.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 26/01/2021.
//

import Foundation
import CoreLocation

struct PathPoint {
    let location: CLLocationCoordinate2D
    let measurement: Double
}

extension PathPoint {
    static var fakePathPoint = PathPoint(location: CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0), measurement: 20.0)
}
