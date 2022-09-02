// Created by Lunar on 17/05/2022.
//

import Foundation
import CoreLocation

/// Describes objects capable of providing location
protocol LocationService {
    /// Get currently fetched location
    /// - Returns: Location or `nil` if it cannot be determined
    func getCurrentLocation() throws -> CLLocationCoordinate2D?
}
