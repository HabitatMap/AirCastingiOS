// Created by Lunar on 24/05/2022.
//

import Foundation
import CoreLocation

extension ExternalSessionEntity: Sessionable {
    var gotDeleted: Bool {
        false
    }
    
    var userInterface: UIStateEntity? {
        get { uiState }
        set { uiState = newValue }
    }
    
    var location: CLLocationCoordinate2D? {
        get {
            guard let lat = value(forKey: "latitude") as? CLLocationDegrees,
                  let lon = value(forKey: "longitude") as? CLLocationDegrees else {
                      return nil
                  }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        set {
            setValue(newValue?.latitude, forKey: "latitude")
            setValue(newValue?.longitude, forKey: "longitude")
        }
    }
    
    var isFixed: Bool {
        return true
    }
    
    var isExternal: Bool {
        return true
    }
    
    var isActive: Bool {
        return true
    }
}
