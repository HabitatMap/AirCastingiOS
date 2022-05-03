// Created by Lunar on 28/02/2022.
//

import UIKit
import CoreLocation

struct MapSessionMarker {
    let id: Int
    let username: String
    let uuid: String
    let title: String
    let location: CLLocationCoordinate2D
    let startTime: String
    let endTime: String
    let markerImage: UIImage
    let streams: [Stream]
    
    struct Stream {
        let id: Int
        let unitName: String
        let unitSymbol: String
        let sensorName: String
        let sensorPackageName: String
        let thresholdsValues: ThresholdsValue
    }
}
