// Created by Lunar on 28/02/2022.
//

import Foundation
import SwiftUI

struct ChartDot {
    let value: Double
    let color: Color
}

class SearchAndFollowChartViewModel: ObservableObject {
    @Published var entries: [ChartDot] = []
    
    let numberOfEntries = 9
    
    func generateEntries(with measurements: [Double], thresholds: ThresholdsValue) {
        entries = measurements.suffix(9).map {
            return ChartDot(value: $0, color: thresholds.colorFor(value: $0))
        }
    }
    
//    private func intervalEndTime(for stream: StreamWithMeasurementsDownstream) -> Date? {
//        guard let measurement = stream.measurements.last else { return nil }
//        return DateBuilder.getDateWithTimeIntervalSinceReferenceDate(Double(measurement.time))
//    }
    
    
}
