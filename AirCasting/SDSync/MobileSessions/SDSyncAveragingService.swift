// Created by Lunar on 29/09/2022.
//

import Foundation
import CoreLocation

protocol SDSyncAveragingService {
    /// `action` parameter, is a completion block which is executed each time when measurements in an interval get averaged. First argument is an averaged measurement, and second is an array of measurements from which the average was calculated.
    func averageMeasurementsWithReminder<T: AverageableMeasurement>(measurements: [T], startTime: Date, averagingWindow: AveragingWindow, action: (T, [T]) -> Void) -> [T]
    func calculateAveragingWindow(startTime: Date, lastMeasurement: Date) -> AveragingWindow
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
    func averageMeasurementsWithReminder<T: AverageableMeasurement>(measurements: [T], startTime: Date, averagingWindow: AveragingWindow, action: (T, [T]) -> Void) -> [T] {
        var intervalStart = startTime
        var intervalEnd = intervalStart.addingTimeInterval(TimeInterval(averagingWindow.rawValue))
        
        var measurementsBuffer = [T]()
        
        measurements.forEach { measurement in
            guard measurement.measuredAt >= intervalStart else { return }
            
            guard measurement.measuredAt < intervalEnd else {
                // If there are any measurements in the buffer we should average them
                if let newMeasurement = averageMeasurements(measurementsBuffer, time: intervalEnd-1) {
                    action(newMeasurement, measurementsBuffer)
                }
                
                // There can be a long break between measurements. If the current measurement fall outside of the interval we should find the next interval that contains the measurement
                findNextTimeInterval(measurement: measurement, intervalStart: &intervalStart, intervalEnd: &intervalEnd, averagingWindow: averagingWindow)
                measurementsBuffer = [measurement]
                return
            }
            
            measurementsBuffer.append(measurement)
        }
        
        // If the last interval was full then we should average measurements contained in it as well
        if measurementsBuffer.last?.measuredAt == intervalEnd - 1 {
            if let newMeasurement = averageMeasurements(measurementsBuffer, time: intervalEnd-1) {
                action(newMeasurement, measurementsBuffer)
            }
            measurementsBuffer = []
        }
        
        return measurementsBuffer
    }
    
    func calculateAveragingWindow(startTime: Date, lastMeasurement: Date) -> AveragingWindow {
        let sessionDuration = abs(lastMeasurement.timeIntervalSince(startTime))
        if sessionDuration <= TimeInterval(TimeThreshold.firstThreshold.rawValue) {
            return .zeroWindow
        } else if sessionDuration <= TimeInterval(TimeThreshold.secondThreshold.rawValue) {
            return .firstThresholdWindow
        }
        return .secondThresholdWindow
    }
    
    private func findNextTimeInterval(measurement: AverageableMeasurement, intervalStart: inout Date, intervalEnd: inout Date, averagingWindow: AveragingWindow) {
        while measurement.measuredAt >= intervalEnd {
            // Helper variables for debugging
            let logMeasurementTime = measurement.measuredAt
            let logIntervalEnd = intervalEnd
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
