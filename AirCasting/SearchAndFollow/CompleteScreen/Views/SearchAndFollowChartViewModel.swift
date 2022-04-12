// Created by Lunar on 28/02/2022.
//

import Foundation
import SwiftUI

class SearchAndFollowChartViewModel: ObservableObject {
    struct ChartDot {
        let value: Double
        let color: Color
    }
    struct ChartMeasurement {
        let value: Double
        let time: Date
    }
    
    @Published var entries: [ChartDot] = []
    
    let numberOfEntries = 9
    
    func generateEntries(with measurements: [ChartMeasurement], thresholds: ThresholdsValue) -> (Date?, Date?) {
        var times: [Date] = []
        entries = measurements.suffix(numberOfEntries).map {
            times.append($0.time)
            return ChartDot(value: $0.value, color: thresholds.colorFor(value: $0.value))
        }
        
        return (startTime: times.min(), endTime: times.max())
    }
}
