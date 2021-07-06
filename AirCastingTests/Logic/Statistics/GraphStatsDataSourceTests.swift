// Created by Lunar on 06/07/2021.
//

import XCTest
@testable import AirCasting

class GraphStatsDataSourceTests: XCTestCase {
    let stream = TestStreamGenerator.createStream(numberOfMeasurements: 100)
    
    override func tearDown() {
        persistence.viewContext.delete(stream)
    }
    
    func test_allMeasurements_returnsCorrectMeasurementsSet() {
        let dataSource = createDataSource()
        assertContainsSameElements(dataSource.allMeasurements.map { $0.value }, stream.allMeasurements!.map { $0.value })
        assertContainsSameElements(dataSource.allMeasurements.map { $0.measurementTime }, stream.allMeasurements!.map { $0.time })
    }
    
    func test_visibleMeasurements_afterInit_returnsAllMeasurements() {
        let dataSource = createDataSource()
        assertContainsSameElements(dataSource.visibleMeasurements.map { $0.value }, stream.allMeasurements!.map { $0.value })
        assertContainsSameElements(dataSource.visibleMeasurements.map { $0.measurementTime }, stream.allMeasurements!.map { $0.time })
    }
    
    func test_whenAskingForVisibleMeasurements_returnsCorrectData() {
        let dataSource = createDataSource()
        // See `createStream` doc to undestand what's expected here
        dataSource.dateRange = Date(timeIntervalSince1970: 50)...Date.distantFuture
        assertContainsSameElements(dataSource.visibleMeasurements.map { $0.value }, stream.allMeasurements!.dropFirst(50).map { $0.value })
        assertContainsSameElements(dataSource.visibleMeasurements.map { $0.measurementTime }, stream.allMeasurements!.dropFirst(50).map { $0.time })
    }
    
    private func createDataSource() -> GraphStatsDataSource {
        let dataSource = GraphStatsDataSource(stream: stream)
        return dataSource
    }
}
