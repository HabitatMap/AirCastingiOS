// Created by Lunar on 13/10/2022.
//

import XCTest
@testable import AirCasting

extension SDSyncMeasurement: Equatable {
    public static func == (lhs: AirCasting.SDSyncMeasurement, rhs: AirCasting.SDSyncMeasurement) -> Bool {
        lhs.measuredAt == rhs.measuredAt && lhs.value == rhs.value && lhs.location?.latitude == rhs.location?.latitude && lhs.location?.longitude == rhs.location?.longitude
    }
}

final class SdSyncAveragingServiceTests: XCTestCase {
    let service = DefaultSDSyncAveragingService()

    func test_averageMeasurementsWithReminderCalled_returnsUnaveragedMeasurementsAsReminder() throws {
        let date = Date()
        
        let measurements = [SDSyncMeasurement(measuredAt: date, value: 3)]
        
        let reminder = service.averageMeasurementsWithReminder(measurements: measurements, startTime: date, averagingWindow: .firstThresholdWindow, action: { _, _ in })
        XCTAssertEqual(reminder, measurements)
    }
    
    func test_averageMeasurementsWithReminderCalled_callsCompletionWithAnAveragedMeasurement() throws {
        let thresholdWindow = AveragingWindow.firstThresholdWindow
        let startDate = Date.init(timeInterval: TimeInterval(-thresholdWindow.rawValue * 5), since: Date())
        
        let measurements = [SDSyncMeasurement(measuredAt: startDate, value: 2),
                            SDSyncMeasurement(measuredAt: startDate+1, value: 1),
                            SDSyncMeasurement(measuredAt: startDate+TimeInterval(thresholdWindow.rawValue), value: 3)]
        
        var averagedMeasurement: SDSyncMeasurement?
        
        let reminder = service.averageMeasurementsWithReminder(measurements: measurements, startTime: startDate, averagingWindow: .firstThresholdWindow, action: { measurement, _ in averagedMeasurement = measurement })
        
        XCTAssertEqual(reminder, [SDSyncMeasurement(measuredAt: startDate+TimeInterval(thresholdWindow.rawValue), value: 3)])
        XCTAssertEqual(averagedMeasurement, SDSyncMeasurement(measuredAt: startDate + TimeInterval(thresholdWindow.rawValue) - 1, value: 1.5))
    }
    
    func test_averageMeasurementsWithReminderCalled_callsCompletionWithMeasurementsFromInterval() throws {
        let thresholdWindow = AveragingWindow.firstThresholdWindow
        let startDate = Date.init(timeInterval: TimeInterval(-thresholdWindow.rawValue * 5), since: Date())
        
        let measurements = [SDSyncMeasurement(measuredAt: startDate, value: 2),
                            SDSyncMeasurement(measuredAt: startDate+1, value: 1),
                            SDSyncMeasurement(measuredAt: startDate+TimeInterval(thresholdWindow.rawValue), value: 3)]
        
        var measurementsInInterval: [SDSyncMeasurement] = []
        
        let reminder = service.averageMeasurementsWithReminder(measurements: measurements, startTime: startDate, averagingWindow: .firstThresholdWindow, action: { _, measurements in measurementsInInterval = measurements })
        
        XCTAssertEqual(reminder, [SDSyncMeasurement(measuredAt: startDate+TimeInterval(thresholdWindow.rawValue), value: 3)])
        XCTAssertEqual(measurementsInInterval, [SDSyncMeasurement(measuredAt: startDate, value: 2), SDSyncMeasurement(measuredAt: startDate+1, value: 1)])
    }
    
    func test_averageMeasurementsWithReminderCalledForFirstThresholdWindow_calculatesRightAverages() throws {
        let thresholdWindow = AveragingWindow.firstThresholdWindow
        let numberOfIntervals = 6
        let startDate = Date.init(timeInterval: TimeInterval(-thresholdWindow.rawValue * numberOfIntervals), since: Date())
        
        var measurements: [SDSyncMeasurement] = []
        var expectedAverages: [Double] = []
        var valuesForAveraging: [Double] = []
        
        for i in 0...numberOfIntervals*thresholdWindow.rawValue {
            if i != 0 && i%thresholdWindow.rawValue == 0 {
                expectedAverages.append(valuesForAveraging.reduce(0.0, +) / Double(valuesForAveraging.count))
                valuesForAveraging = []
            }
            valuesForAveraging.append(Double(i))
            measurements.append(SDSyncMeasurement(measuredAt: startDate + TimeInterval(i), value: Double(i)))
        }
        
        var resultMeasurements: [SDSyncMeasurement] = []
        
        let reminder = service.averageMeasurementsWithReminder(measurements: measurements, startTime: startDate, averagingWindow: thresholdWindow, action: { measurement, _ in resultMeasurements.append(measurement) })
        
        XCTAssertEqual(resultMeasurements.map(\.value), expectedAverages)
    }
    
    func test_averageMeasurementsWithReminderCalledForSecondWindow_calculatesRightAverages() throws {
        let thresholdWindow = AveragingWindow.secondThresholdWindow
        let numberOfIntervals = 6
        let startDate = Date.init(timeInterval: TimeInterval(-thresholdWindow.rawValue * numberOfIntervals), since: Date())
        
        var measurements: [SDSyncMeasurement] = []
        var expectedAverages: [Double] = []
        var valuesForAveraging: [Double] = []
        
        for i in 0...numberOfIntervals*thresholdWindow.rawValue {
            if i != 0 && i%thresholdWindow.rawValue == 0 {
                expectedAverages.append(valuesForAveraging.reduce(0.0, +) / Double(valuesForAveraging.count))
                valuesForAveraging = []
            }
            valuesForAveraging.append(Double(i))
            measurements.append(SDSyncMeasurement(measuredAt: startDate + TimeInterval(i), value: Double(i)))
        }
        
        var resultMeasurements: [SDSyncMeasurement] = []
        
        _ = service.averageMeasurementsWithReminder(measurements: measurements, startTime: startDate, averagingWindow: thresholdWindow, action: { measurement, _ in resultMeasurements.append(measurement) })
        
        XCTAssertEqual(resultMeasurements.map(\.value), expectedAverages)
    }
    
    func test_averageMeasurementsWithReminderCalledWithBigGapBetweenMeasurements_calculatesRightAverages() throws {
        let thresholdWindow = AveragingWindow.secondThresholdWindow
        let numberOfIntervals = 60
        let startDate = Date.init(timeInterval: TimeInterval(-thresholdWindow.rawValue * numberOfIntervals), since: Date())
        
        var measurements: [SDSyncMeasurement] = []
        var expectedAverages: [Double] = []
        var valuesForAveraging: [Double] = []
        
        for i in 0...numberOfIntervals*thresholdWindow.rawValue {
            if i != 0 && !valuesForAveraging.isEmpty && i%thresholdWindow.rawValue == 0 {
                expectedAverages.append(valuesForAveraging.reduce(0.0, +) / Double(valuesForAveraging.count))
                valuesForAveraging = []
            }
            if i > 70 && i < numberOfIntervals*thresholdWindow.rawValue-100 {
                continue
            }
            valuesForAveraging.append(Double(i))
            measurements.append(SDSyncMeasurement(measuredAt: startDate + TimeInterval(i), value: Double(i)))
        }
        
        var resultMeasurements: [SDSyncMeasurement] = []
        
        let reminder = service.averageMeasurementsWithReminder(measurements: measurements, startTime: startDate, averagingWindow: thresholdWindow, action: { measurement, _ in resultMeasurements.append(measurement) })
        
        XCTAssertEqual(resultMeasurements.map(\.value), expectedAverages)
        XCTAssertEqual(reminder, [SDSyncMeasurement(measuredAt: startDate+TimeInterval(numberOfIntervals*thresholdWindow.rawValue), value: Double(numberOfIntervals*thresholdWindow.rawValue))])
    }
}
