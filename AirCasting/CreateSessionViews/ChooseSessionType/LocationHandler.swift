// Created by Lunar on 04/08/2021.
//

import Foundation
import CoreLocation

protocol LocationHandler {
    var locationTracker: LocationTracker { get }
    func isLocationDenied() -> Bool
}

class DefaultLocationHandler: LocationHandler {
    var locationTracker: LocationTracker
    
    init(locationTracker: LocationTracker) {
        self.locationTracker = locationTracker
    }
    
    func isLocationDenied() -> Bool {
        locationTracker.locationGranted == .denied ? true : false
    }
}

#if DEBUG
class DummyDefaultLocationHandler: LocationHandler {
    var locationTracker = LocationTracker(locationManager: CLLocationManager())
    
    func isLocationDenied() -> Bool {
        locationTracker.locationGranted == .denied ? true : false
    }
}
#endif
