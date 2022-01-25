// Created by Lunar on 06/07/2021.
//

import Foundation

enum MeasurementStatistics {
    enum Statistic: CaseIterable, Equatable {
        case average
        case latest
        case high
    }
    
    enum StreamType: String {
        case temperature = "Temperature"
        case pm = "Particulate Matter"
        case humidity = "Humidity"
    }
    
    struct StatisticItem: Equatable {
        let stat: Statistic
        let value: Double
        let type: StreamType
    }
    
    struct Measurement: Equatable {
        let measurementTime: Date
        let value: Double
        let type: StreamType
    }
}

extension MeasurementStatistics.StreamType {
    init(_ rawValue: String?) {
        switch rawValue {
        case "Temperature":
            self = .temperature
        case "Humidity":
            self = .humidity
        default:
            self = .pm
        }
    }
}
