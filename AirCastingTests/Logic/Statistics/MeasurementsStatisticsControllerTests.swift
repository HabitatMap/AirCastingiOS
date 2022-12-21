// Created by Lunar on 05/07/2021.
//

import XCTest
import Resolver
@testable import AirCasting

class MeasurementsStatisticsControllerTests: ACTestCase {
    let outputSpy = OutputSpy()
    let dataSourceMock = DataSourceMock()
    let calculatorMock = CalculatorMock()
    let timerMock = ScheduledTimerSettableMock()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.timerMock as ScheduledTimerSettable }
    }
    
    func test_whenVisibleDataChanges_calculatesOnlyDesiredStats() {
        let desiredStats: [MeasurementStatistics.Statistic] = [.average, .high]
        let controller = controller(for: desiredStats)
        
        controller.computeStatistics()
        
        XCTAssertEqual(calculatorMock.history.count, 2)
        let calculatedStats = calculatorMock.history.map { $0.statistic }
        assertContainsSameElements(calculatedStats, desiredStats)
    }
    
    func test_whenVisibleDataChanges_usesCalculatedValuesToProduceOutput() {
        let controller = controller()
        let calculatedAvg = 10.0
        let calculatedHigh = 15.0
        let calculatedLatest = 20.0
        calculatorMock.stubbedValues = [
            .average: calculatedAvg, .high: calculatedHigh, .latest: calculatedLatest
        ]
        
        controller.computeStatistics()
        
        XCTAssertEqual(calculatorMock.history.count, 3)
        XCTAssertEqual(outputSpy.history.count, 1)
        guard case .statsChanged(let stats) = outputSpy.history.first else {
            XCTFail("Unexpected error!")
            return
        }
        assertContainsSameElements(stats, [.init(stat: .average, value: calculatedAvg),
                                           .init(stat: .high, value: calculatedHigh),
                                           .init(stat: .latest, value: calculatedLatest)])
    }
    
    func test_whenVisibleDataChanges_andCalculatingLatestValue_itPassessAllMeasurementsToCalculator() {
        let controller = controller(for: [.latest])
        
        controller.computeStatistics()
        
        XCTAssertEqual(calculatorMock.history.count, 1)
        XCTAssertEqual(calculatorMock.history.first!.measurements, dataSourceMock.allMeasurements)
    }
    
    func test_whenVisibleDataChanges_andCalculatingHighestValue_itPassessOnlyVisibleMeasurementsToCalculator() {
        let controller = controller(for: [.high])
        
        controller.computeStatistics()
        
        XCTAssertEqual(calculatorMock.history.count, 1)
        XCTAssertEqual(calculatorMock.history.first!.measurements, dataSourceMock.visibleMeasurements)
    }
    
    func test_whenDateRangeChanges_andCalculatingAverageValue_itPassessOnlyVisibleMeasurementsToCalculator() {
        let controller = controller(for: [.average])
        
        controller.computeStatistics()
        
        XCTAssertEqual(calculatorMock.history.count, 1)
        XCTAssertEqual(calculatorMock.history.first!.measurements, dataSourceMock.visibleMeasurements)
    }
    
    func test_whenContinueousModeIsEnabled_itCreatesATimer() {
        let controller = controller(interval: 1)
        controller.continuousModeEnabled = true
        XCTAssertEqual(outputSpy.history.count, 0)
        timerMock.fireTimer()
        XCTAssertEqual(outputSpy.history.count, 1)
    }
    
    func test_whenContinueousModeIsDisabled_itDestroysATimer() {
        let controller = controller(interval: 1)
        controller.continuousModeEnabled = true
        XCTAssertEqual(timerMock.invalidationHistory, 0)
        controller.continuousModeEnabled = false
        XCTAssertEqual(timerMock.invalidationHistory, 1)
    }
    
    func test_whenDataSourceRequestsForceRefresh_itRefreshesData() {
        let controller = controller()
        controller.computeStatistics()
        XCTAssertEqual(outputSpy.history.count, 1)
        dataSourceMock.onForceReload?()
        XCTAssertEqual(outputSpy.history.count, 2)
    }
    
    // MARK: - Private helpers
    
    private func controller(for stats: [MeasurementStatistics.Statistic] = MeasurementStatistics.Statistic.allCases, interval: Double? = 1) -> MeasurementsStatisticsController {
        let controller = MeasurementsStatisticsController(dataSource: dataSourceMock,
                                                          calculator: calculatorMock,
                                                          desiredStats: stats,
                                                          computeStatisticsInterval: interval)
        controller.output = outputSpy
        return controller
    }
    
    // MARK: - Doubles
    
    final class OutputSpy: MeasurementsStatisticsOutput {
        enum HistoryItem {
            case statsChanged(stats: [MeasurementStatistics.StatisticItem])
        }
        
        var history: [HistoryItem] = []
        
        func statisticsDidChange(to stats: [MeasurementStatistics.StatisticItem]) {
            history.append(.statsChanged(stats: stats))
        }
    }

    final class DataSourceMock: MeasurementsStatisticsDataSource {
        var onForceReload: (() -> Void)?
        
        var allMeasurements: [MeasurementStatistics.Measurement] = .init(creating: .random(), times: 25)
        
        var visibleMeasurements: [MeasurementStatistics.Measurement] {
            Array(allMeasurements.dropFirst(10))
        }
    }

    final class CalculatorMock: StatisticsCalculator {
        var stubbedValues: [MeasurementStatistics.Statistic : Double] = [:]
        
        struct HistoryItem: Equatable {
            let statistic: MeasurementStatistics.Statistic
            let measurements: [MeasurementStatistics.Measurement]
        }
        
        var history: [HistoryItem] = []
        
        func calculateValue(for stat: MeasurementStatistics.Statistic, from measurements: [MeasurementStatistics.Measurement]) -> Double {
            let stubbedValueForStat = stubbedValues[stat]
            history.append(.init(statistic: stat, measurements: measurements))
            return stubbedValueForStat ?? 1.0
        }
    }

}

extension MeasurementStatistics.Measurement {
    static func random() -> Self {
        .init(measurementTime: Date().addingTimeInterval(.random(in: -3600...3600)), value: .random(in: -100.0...100.0))
    }
}
