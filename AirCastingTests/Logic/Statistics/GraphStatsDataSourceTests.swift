// Created by Lunar on 06/07/2021.
//

import XCTest
@testable import AirCasting

class GraphStatsDataSourceTests: ACTestCase {
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
    
    func test_whenStreamIsChanged_itForcesAReload() {
        let dataSource = createDataSource()
        var forceReloadCalledTimes = 0
        dataSource.onForceReload = { forceReloadCalledTimes += 1 }
        let newStream = TestStreamGenerator.createStream(numberOfMeasurements: 5)
        dataSource.stream = newStream
        XCTAssertEqual(forceReloadCalledTimes, 1)
    }
    
    func test_whenStreamIsChanged_itReturnsNewDataCorrectly() {
        let dataSource = createDataSource()
        let newStream = TestStreamGenerator.createStream(numberOfMeasurements: 5)
        dataSource.stream = newStream
        assertContainsSameElements(dataSource.visibleMeasurements.map(\.value), newStream.allMeasurements!.map(\.value))
    }
    
    private func createDataSource() -> GraphStatsDataSource {
        let dataSource = GraphStatsDataSource()
        dataSource.stream = stream
        return dataSource
    }
}
