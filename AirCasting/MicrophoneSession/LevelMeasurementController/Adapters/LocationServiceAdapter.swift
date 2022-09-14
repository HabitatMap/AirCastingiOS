// Created by Lunar on 26/07/2022.
//

import Foundation
import CoreLocation

/// An adapter for `Location tracker` conforming to `LocationService` so it can speak to `LevelMeasurementController`
class LocationServiceAdapter: LocationService {
    private let tracker: LocationTracker
    
    init(tracker: LocationTracker) {
        self.tracker = tracker
        tracker.start()
    }
    
    deinit {
        tracker.stop()
    }
    
    func getCurrentLocation() throws -> CLLocationCoordinate2D? {
        tracker.location.value?.coordinate
    }
}
