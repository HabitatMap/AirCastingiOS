// Created by Lunar on 29/11/2021.
//

import GoogleMaps
import Foundation

struct VisibleRegionCoordinates {
    var latNorth: CLLocationDegrees
    var latSouth: CLLocationDegrees
    var lonEast: CLLocationDegrees
    var lonWest: CLLocationDegrees
    
    init(_ latNorth: CLLocationDegrees, _ latSouth: CLLocationDegrees, _ lonEast: CLLocationDegrees, _ lonWest: CLLocationDegrees) {
        self.latNorth = latNorth
        self.latSouth = latSouth
        self.lonEast = lonEast
        self.lonWest = lonWest
    }
}
