// Created by Lunar on 28/02/2022.
//

import UIKit
import CoreLocation

struct MapSessionMarker: Equatable {
    static func == (lhs: MapSessionMarker, rhs: MapSessionMarker) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: Int
    let username: String
    let uuid: String
    let title: String
    let location: CLLocationCoordinate2D
    let startTime: String
    let endTime: String
    let markerImage: UIImage
    let streamId: Int
    let thresholdsValues: ThresholdsValue
}
