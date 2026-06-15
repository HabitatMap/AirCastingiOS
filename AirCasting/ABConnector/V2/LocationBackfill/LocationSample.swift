// V2 disconnect-window location backfill.
//
// Plain-old struct used by the backfill coordinator/sampler/store as the
// in-memory representation of a persisted location fix. CoreData rows are
// materialized into this type for lookup matching.

import Foundation
import CoreLocation

struct LocationSample: Equatable {
    let sessionUUID: SessionUUID
    let timestamp: Date
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
