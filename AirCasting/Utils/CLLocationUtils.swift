// Created by Lunar on 14/06/2021.
//

import CoreLocation

extension CLLocationCoordinate2D: Equatable { }

extension CLLocationCoordinate2D {
    public init?(latitude: Double?, longitude: Double?) {
        guard let lat = latitude, let long = longitude else { return nil }
        self.init(latitude: .init(lat), longitude: .init(long))
    }
}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

extension Optional where Wrapped == Double {
    var locationDegrees: CLLocationDegrees {
        guard case .some(let value) = self else { return .zero }
        return CLLocationDegrees(value)
    }
}

extension CLLocationCoordinate2D {
    //
    // https://en.wikipedia.org/wiki/Null_Island
    //
    // since 0 is exactly representable as an IEEE754 floating-point number
    // comparison with 0 should be safe here:
    var isLocationLess: Bool {
        return latitude == 0.0 && longitude == 0.0
    }
}
