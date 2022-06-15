// Created by Lunar on 13/01/2022.
//

import Foundation
import CoreLocation

extension Database {
    public struct Note: Hashable {
        public let date: Date
        public let text: String
        public let latitude: Double
        public let longitude: Double
        public let number: Int
        public let originalPictureData: Data?
        
        public init(
            date: Date,
            text: String,
            latitude: Double,
            longitude: Double,
            number: Int,
            originalPictureData: Data? = nil
        ) {
            self.date = date
            self.text = text
            self.latitude = latitude
            self.longitude = longitude
            self.number = number
            self.originalPictureData = originalPictureData
        }
    }
}
