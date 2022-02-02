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
    var measurement: Double = 20
    #warning("Do something with hard coded measurement")
}

extension PathPoint {
    static var fakePathPoint = PathPoint(location: .undefined, measurementTime: DateBuilder.getRawDate())
}
