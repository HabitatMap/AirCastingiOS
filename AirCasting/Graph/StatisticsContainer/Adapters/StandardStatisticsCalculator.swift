// Created by Lunar on 06/07/2021.
//

import Foundation

class StandardStatisticsCalculator: StatisticsCalculator {
    func calculateValue(for stat: MeasurementStatistics.Statistic, from measurements: [MeasurementStatistics.Measurement]) -> Double {
        switch stat {
        case .average: return calculateAverage(from: measurements)
        case .high: return calculateHigh(from: measurements)
        case .latest: return getLatest(from: measurements)
        }
    }
    
    private func calculateAverage(from measurements: [MeasurementStatistics.Measurement]) -> Double {
        guard measurements.count > 0 else { return 0 } // If empty default to 0.0
        let summed = measurements.map(\.value).reduce(0, +)
        return summed / Double(measurements.count)
    }
    
    private func calculateHigh(from measurements: [MeasurementStatistics.Measurement]) -> Double {
        measurements.map(\.value).max() ?? 0.0 // If empty default to 0.0
    }
    
    private func getLatest(from measurements: [MeasurementStatistics.Measurement]) -> Double {
        measurements.sorted { $0.measurementTime < $1.measurementTime }.last?.value ?? 0.0 // If empty default to 0.0
    }
}
