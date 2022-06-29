// Created by Lunar on 04/08/2021.
//

import Foundation
import CoreLocation
import Resolver

//protocol LocationHandler {
//    func isLocationDenied() -> Bool
//    func requestAuthorisation()
//}
//
//class DefaultLocationHandler: LocationHandler {
//    @Injected private var locationTracker: LocationTracker
//
//    func isLocationDenied() -> Bool {
//        locationTracker.locationGranted == .denied ? true : false
//    }
//
//    func requestAuthorisation() {
//        locationTracker.requestAuthorisation()
//    }
//}
//
//#if DEBUG
//class DummyDefaultLocationHandler: LocationHandler {
//
//    var locationTracker = LocationTracker(locationManager: CLLocationManager())
//
//    func isLocationDenied() -> Bool {
//        locationTracker.locationGranted == .denied ? true : false
//    }
//
//    func requestAuthorisation() { }
//}
//#endif
