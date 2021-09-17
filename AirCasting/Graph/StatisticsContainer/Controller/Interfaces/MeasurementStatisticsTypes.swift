// Created by Lunar on 06/07/2021.
//

import Foundation

enum MeasurementStatistics {
    enum Statistic: CaseIterable, Equatable {
        case average
        case latest
        case high
    }
    
    struct StatisticItem: Equatable {
        let stat: Statistic
        let value: Double
    }
    
    struct Measurement: Equatable {
        let measurementTime: Date
        let value: Double
    }
}
