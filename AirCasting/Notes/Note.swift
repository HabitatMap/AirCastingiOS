// Created by Lunar on 16/12/2021.
//

import Foundation
import CoreLocation

struct Note {
    let date: Date
    let text: String
    let lat: CLLocationDegrees
    let long: CLLocationDegrees
    let pictureData: Data?
    let number: Int
}
