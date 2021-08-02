// Created by Lunar on 16/07/2021.
//

import Foundation

extension Array where Element == SensorThreshold {
    
    func threshold(for stream: MeasurementStreamEntity?) -> SensorThreshold? {
        first { threshold in
            threshold.sensorName?.lowercased() == stream?.sensorName?.lowercased()
        }
    }
    
}
