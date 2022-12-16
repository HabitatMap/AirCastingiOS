//
//  HeatMapPoint.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 26/01/2021.
//

import Foundation
import CoreLocation

struct HeatMapPoint: Equatable {
    static func == (lhs: HeatMapPoint, rhs: HeatMapPoint) -> Bool {
        rhs.measurement == lhs.measurement &&
        rhs.location.latitude == lhs.location.latitude &&
        rhs.location.longitude == lhs.location.longitude
    }
    
    let location: CLLocationCoordinate2D
    var measurement: Double
}
