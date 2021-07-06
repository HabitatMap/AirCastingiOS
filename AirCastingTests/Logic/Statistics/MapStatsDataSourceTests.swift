// Created by Lunar on 06/07/2021.
//

import XCTest
import CoreLocation
@testable import AirCasting

class MapStatsDataSourceTests: XCTestCase {
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
        dataSource.visiblePathPoints = [
            PathPoint(location: CLLocationCoordinate2D(latitude: 20.0, longitude: 10.0), measurementTime: Date(timeIntervalSinceReferenceDate: 0), measurement: 1.0),
            PathPoint(location: CLLocationCoordinate2D(latitude: 10.0, longitude: 20.0), measurementTime: Date(timeIntervalSinceReferenceDate: 10), measurement: 12.0)
        ]
        assertContainsSameElements(dataSource.visibleMeasurements.map { $0.value }, [1.0, 12.0])
        assertContainsSameElements(dataSource.visibleMeasurements.map { $0.measurementTime }, [Date(timeIntervalSinceReferenceDate: 0), Date(timeIntervalSinceReferenceDate: 10)])
    }
    
    private func createDataSource() -> MapStatsDataSource {
        let dataSource = MapStatsDataSource(stream: stream)
        return dataSource
    }
}
