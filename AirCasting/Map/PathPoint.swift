//
//  PathPoint.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 26/01/2021.
//

import Foundation
import CoreLocation

struct PathPoint: Equatable {
    static func == (lhs: PathPoint, rhs: PathPoint) -> Bool {
        rhs.measurementTime == lhs.measurementTime &&
        rhs.measurement == lhs.measurement &&
        rhs.location.latitude == lhs.location.latitude &&
        rhs.location.longitude == lhs.location.longitude
    }
    
    let location: CLLocationCoordinate2D
    let measurementTime: Date
    let measurement: Double
}

extension PathPoint {
    static var fakePathPoint = PathPoint(location: CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0), measurementTime: Date(), measurement: 20.0)
}
