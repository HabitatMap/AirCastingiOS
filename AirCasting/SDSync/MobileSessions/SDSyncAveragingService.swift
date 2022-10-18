// Created by Lunar on 29/09/2022.
//

import Foundation
import CoreLocation

protocol SDSyncAveragingService {
    /// `averagingAction` parameter, is a completion block which is executed each time when measurements in an interval get averaged. First argument is an averaged measurement, and second is an array of measurements from which the average was calculated.
    func averageMeasurementsWithReminder<T: AverageableMeasurement>(measurements: [T], startTime: Date, averagingWindow: AveragingWindow, averagingAction: (T, [T]) -> Void) -> [T]
}

protocol AverageableMeasurement {
    var measuredAt: Date { get set }
    var value: Double { get set }
    var location: CLLocationCoordinate2D? { get set }
}
extension MeasurementEntity: AverageableMeasurement {
    var measuredAt: Date {
        get {
            time
        }
        set {
            time = newValue
        }
    }
}

class DefaultSDSyncAveragingService: SDSyncAveragingService {
    func averageMeasurementsWithReminder<T: AverageableMeasurement>(measurements: [T], startTime: Date, averagingWindow: AveragingWindow, averagingAction: (T, [T]) -> Void) -> [T] {
        var intervalStart = startTime
        var intervalEnd = intervalStart.addingTimeInterval(TimeInterval(averagingWindow.rawValue))
        
        var measurementsBuffer = [T]()
        
        measurements.forEach { measurement in
            guard measurement.measuredAt >= intervalStart else { return }
            
            guard measurement.measuredAt < intervalEnd else {
                Log.info("Averaging happening. count: \(measurementsBuffer.count), first meas. time: \(measurementsBuffer.first?.measuredAt), last meas. time:\(measurementsBuffer.last?.measuredAt)")
                // If there are any measurements in the buffer we should average them
                if let newMeasurement = averageMeasurements(measurementsBuffer, time: intervalEnd-1) {
                    averagingAction(newMeasurement, measurementsBuffer)
                }
                
                // There can be a long break between measurements. If the current measurement fall outside of the interval we should find the next interval that contains the measurement
                findNextTimeInterval(measurement: measurement, intervalStart: &intervalStart, intervalEnd: &intervalEnd, averagingWindow: averagingWindow)
                Log.info("Appending measurement from \(measurement.measuredAt), interval end: \(intervalEnd)")
                measurementsBuffer = [measurement]
                return
            }
            
            Log.info("Buffer count is \(measurementsBuffer.count), appending measurement \(measurement.measuredAt)")
            
            measurementsBuffer.append(measurement)
        }
        
        if measurementsBuffer.last?.measuredAt == intervalEnd - 1 {
            Log.info("Averaging reminder with last at: \(measurementsBuffer.last?.measuredAt); interval end time: \(intervalEnd)")
            if let newMeasurement = (averageMeasurements(measurementsBuffer, time: intervalEnd-1) as? T) {
                averagingAction(newMeasurement, measurementsBuffer)
            }
            measurementsBuffer = []
        }
        
        return measurementsBuffer
    }
    
    private func findNextTimeInterval(measurement: AverageableMeasurement, intervalStart: inout Date, intervalEnd: inout Date, averagingWindow: AveragingWindow) {
        while measurement.measuredAt >= intervalEnd {
            // Helper variables for debugging
            let logMeasurementTime = measurement.measuredAt
            let logIntervalEnd = intervalEnd
            Log.info("Measurement time: \(logMeasurementTime), interval end: \(logIntervalEnd). Changing interval.")
            intervalStart = intervalEnd
            intervalEnd = intervalEnd.addingTimeInterval(TimeInterval(averagingWindow.rawValue))
        }
    }
    
    private func averageMeasurements<T: AverageableMeasurement>(_ measurements: [T], time: Date) -> T? {
        guard !measurements.isEmpty else { return nil }
        let average = measurements.map({ $0.value }).reduce(0.0, +) / Double(measurements.count)
        let middleIndex = measurements.count/2
        var middleMeasurement = measurements[middleIndex]
        middleMeasurement.measuredAt = time
        middleMeasurement.value = average
        return middleMeasurement
    }
}