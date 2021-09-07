// Created by Lunar on 05/07/2021.
//

import XCTest
@testable import AirCasting

class StandardStatisticsCalculatorTests: XCTestCase {
    let calculator = StandardStatisticsCalculator()
    
    func test_whenEmptyMeasurementsPassedIn_defaultsToZero() {
        MeasurementStatistics.Statistic.allCases.forEach {
            // We can compare zeros exactly for floating v.:
            XCTAssertEqual(calculator.calculateValue(for: $0, from: []), 0.0)
        }
    }
    
    func test_averageValueCalculation() {
        let average = calculator.calculateValue(for: .average, from: [
            .init(measurementTime: Date(), value: 10.0),
            .init(measurementTime: Date(), value: 20.0),
            .init(measurementTime: Date(), value: 30.0),
            .init(measurementTime: Date(), value: 12.6),
        ])
        XCTAssertEqual(average, 18.15, accuracy: 0.001)
    }
    
    func test_highestValueCalculation() {
        let high = calculator.calculateValue(for: .high, from: [
            .init(measurementTime: Date(), value: 10.0),
            .init(measurementTime: Date(), value: 20.0),
            .init(measurementTime: Date(), value: 30.0),
            .init(measurementTime: Date(), value: 12.6),
        ])
        XCTAssertEqual(high, 30.0, accuracy: 0.001)
    }
    
    func test_latestValueCalculation() {
        let latest = calculator.calculateValue(for: .latest, from: [
            .init(measurementTime: .init(timeIntervalSince1970: 0), value: .default),
            .init(measurementTime: .init(timeIntervalSince1970: 3), value: .default),
            .init(measurementTime: .init(timeIntervalSince1970: 6), value: 440.0),
            .init(measurementTime: .init(timeIntervalSince1970: 1), value: .default),
        ])
        XCTAssertEqual(latest, 440.0, accuracy: 0.001)
    }
}
