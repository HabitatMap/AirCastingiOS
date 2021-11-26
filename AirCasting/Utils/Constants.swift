// Created by Lunar on 20/08/2021.
//

import Foundation

struct Constants {
    enum SensorName {
        static let microphone = "Phone Microphone"
    }
    
    enum Map {
        static let polylineWidth = 5
        static let dotRadius = 10
        static let dotWidth = 20
        static let dotHeight = 20
    }
    
    enum Chart {
        static let numberOfEntries = 9
    }
    
    static let dataFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    enum SDCardSync {
        static let numberOfMeasurementsInDataChunk = 4
    }
}
