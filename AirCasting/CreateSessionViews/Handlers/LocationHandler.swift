// Created by Lunar on 04/08/2021.
//

import Foundation
import CoreLocation

protocol LocationHandler {
    var locationTracker: LocationTracker { get }
    var shouldShowAlert: Bool { get }
    var disableButton: Bool { get }
    func isLocationDenied() -> Bool
    func requestLocation()
}

class DefaultLocationHandler: LocationHandler {
    var locationTracker: LocationTracker
    
    var shouldShowAlert: Bool {
        return locationTracker.locationGranted == .denied
    }
    
    var disableButton: Bool {
        return locationTracker.locationGranted == .denied
    }
    
    init(locationTracker: LocationTracker) {
        self.locationTracker = locationTracker
    }
    
    func isLocationDenied() -> Bool {
        locationTracker.locationGranted == .denied ? true : false
    }
    
    func requestLocation() {
        locationTracker.requestAuthorisation()
    }
}

#if DEBUG
class DummyDefaultLocationHandler: LocationHandler {
    
    var shouldShowAlert: Bool = false
    
    var disableButton: Bool = false
    
    var locationTracker = LocationTracker(locationManager: CLLocationManager())
    
    func isLocationDenied() -> Bool {
        locationTracker.locationGranted == .denied ? true : false
    }
    
    func requestLocation() { }
}
#endif
