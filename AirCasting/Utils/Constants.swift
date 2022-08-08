// Created by Lunar on 20/08/2021.
//

import Foundation

struct Constants {
    enum SensorName {
        static let microphone = "Phone Microphone"
    }

    enum MeasurementType {
        static let temperature = "Temperature"
    }

    enum Map {
        static let polylineWidth = 3
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

    enum UserDefaultsKeys {
        static let crowdMap = "crowdMap"
        static let keepScreenOn = "keepScreenOn"
        static let disableMapping = "disableMapping"
        static let convertToCelsius = "convertToCelsius"
        static let satelliteMapKey = "satteliteMapKey"
        static let twentyFourHoursFormatKey = "twentyFourHourFormatKey"
        static let syncOnlyThroughWifi = "syncOnlyThroughWifi"
        static let dormantSessionsAlert = "dormantSessionsAlert"
    }
    
    enum PrivacyPolicy {
        static let url = URL(string: "https://www.habitatmap.org/aircasting-app-privacy-policy")
    }
}
