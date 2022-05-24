// Created by Lunar on 28/02/2022.
//

import UIKit
import CoreLocation

struct MapSessionMarker: Equatable {
    static func == (lhs: MapSessionMarker, rhs: MapSessionMarker) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: Int
    let location: CLLocationCoordinate2D
    let markerImage: UIImage
    let session: PartialExternalSession
}
