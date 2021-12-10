// Created by Lunar on 06/12/2021.
//

import Foundation
import CoreLocation

struct CSVMeasurement: Encodable {
    let longitude: CLLocationDegrees?
    let latitude: CLLocationDegrees?
    let milliseconds: Int
    let time: Date
    let value: Double?
}
