// Created by Lunar on 05/08/2021.
//

import Foundation

extension Array where Element == MeasurementEntity {
    func getStatistics() -> [MeasurementStatistics.Measurement] {
        map { MeasurementStatistics.Measurement(measurementTime: $0.time, value: $0.value) }
    }
}
