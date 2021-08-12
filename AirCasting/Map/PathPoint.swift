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
        return lhs.location.latitude == rhs.location.latitude && lhs.location.longitude == rhs.location.longitude
    }
    
    let location: CLLocationCoordinate2D
    let measurement: Double
}
