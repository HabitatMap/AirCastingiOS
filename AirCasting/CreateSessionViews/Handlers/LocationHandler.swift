// Created by Lunar on 04/08/2021.
//

import Foundation
import CoreLocation

protocol LocationHandler {
    func isLocationDenied() -> Bool
    func requestAuthorisation()
}

class DefaultLocationHandler: LocationHandler {
    var locationTracker: LocationTracker
    
    init(locationTracker: LocationTracker) {
        self.locationTracker = locationTracker
    }
    
    func isLocationDenied() -> Bool {
        locationTracker.locationGranted == .denied ? true : false
    }
    
    func requestAuthorisation() {
        locationTracker.requestAuthorisation()
    }
}

#if DEBUG
class DummyDefaultLocationHandler: LocationHandler {
    
    var locationTracker = LocationTracker(locationManager: CLLocationManager())
    
    func isLocationDenied() -> Bool {
        locationTracker.locationGranted == .denied ? true : false
    }
    
    func requestAuthorisation() { }
}
#endif
