// Created by Lunar on 29/09/2022.
//

import Foundation
import CoreLocation

protocol SDSyncAveragingService {
    /// `averagingAction` parameter, is a completion block which will be execute after we get averaged measurements
    func averageMeasurementsWithReminder<T: AverageableMeasurement>(measurements: [T], startTime: Date, averagingWindow: AveragingWindow, averagingAction: (T, [T]) -> Void) -> [T]
}

protocol AverageableMeasurement {
    var time: Date! { get set }
    var value: Double { get set }
    var location: CLLocationCoordinate2D? { get set }
}
extension MeasurementEntity: AverageableMeasurement { }

class DefaultSDSyncAveragingService: SDSyncAveragingService {
    func averageMeasurementsWithReminder<T: AverageableMeasurement>(measurements: [T], startTime: Date, averagingWindow: AveragingWindow, averagingAction: (T, [T]) -> Void) -> [T] {
        var intervalStart = startTime
        var intervalEnd = intervalStart.addingTimeInterval(TimeInterval(averagingWindow.rawValue))
        
        var measurementsBuffer = [T]()
        
        measurements.forEach { measurement in
            guard measurement.time >= intervalStart else { return }
            
            guard measurement.time < intervalEnd else {
                Log.info("Averaging happening. count: \(measurementsBuffer.count), first meas. time: \(measurementsBuffer.first?.time), last meas. time:\(measurementsBuffer.last?.time)")
                // If there are any measurements in the buffer we should average them
                if let newMeasurement = averageMeasurements(measurementsBuffer, time: intervalEnd-1) {
                    averagingAction(newMeasurement, measurementsBuffer)
                }
                
                // There can be a long break between measurements. If the current measurement fall outside of the interval we should find the next interval that contains the measurement
                findNextTimeInterval(measurement: measurement, intervalStart: &intervalStart, intervalEnd: &intervalEnd, averagingWindow: averagingWindow)
                measurementsBuffer = [measurement]
                return
            }
            
            measurementsBuffer.append(measurement)
        }
        
        if measurementsBuffer.last?.time == intervalEnd - 1 {
            Log.info("Averaging reminder with last at: \(measurementsBuffer.last?.time) end time: \(intervalEnd)")
            if let newMeasurement = (averageMeasurements(measurementsBuffer, time: intervalEnd-1) as? T) {
                averagingAction(newMeasurement, measurementsBuffer)
            }
            measurementsBuffer = []
        }
        
        return measurementsBuffer
    }
    
    private func findNextTimeInterval(measurement: AverageableMeasurement, intervalStart: inout Date, intervalEnd: inout Date, averagingWindow: AveragingWindow) {
        while measurement.time >= intervalEnd {
            // Helper variables for debugging
            let logMeasurementTime = measurement.time
            let logIntervalEnd = intervalEnd
            Log.info("Measurement time: \(logMeasurementTime), interval end: \(logIntervalEnd)")
            intervalStart = intervalEnd
            intervalEnd = intervalEnd.addingTimeInterval(TimeInterval(averagingWindow.rawValue))
        }
    }
    
    private func averageMeasurements<T: AverageableMeasurement>(_ measurements: [T], time: Date) -> T? {
        guard !measurements.isEmpty else { return nil }
        let average = measurements.map({ $0.value }).reduce(0.0, +) / Double(measurements.count)
        let middleIndex = measurements.count/2
        var middleMeasurement = measurements[middleIndex]
        middleMeasurement.time = time
        middleMeasurement.value = average
        return middleMeasurement
    }
}
