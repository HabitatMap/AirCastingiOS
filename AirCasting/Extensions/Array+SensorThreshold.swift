// Created by Lunar on 16/07/2021.
//

import Foundation

extension Array where Element == SensorThreshold {    
    func threshold(for streamName: String) -> SensorThreshold? {
        guard let symbol = streamName.replacingOccurrences(of: ":", with: "-").split(separator: "-").last else { return nil }
        return first(where: { threshold in
            threshold.sensorName?.contains(symbol) ?? false
        })
    }
}
