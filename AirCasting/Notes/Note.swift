// Created by Lunar on 16/12/2021.
//

import Foundation
import CoreLocation

public class Note: NSObject, Codable {
    var date: Date
    var text: String
    var lat: CLLocationDegrees
    var long: CLLocationDegrees
    var number: Int
    
    init(date: Date,
         text: String,
         lat: CLLocationDegrees,
         long: CLLocationDegrees,
         number: Int) {
        
        self.date = date
        self.text = text
        self.lat = lat
        self.long = long
        self.number = number
    }
}
