// Created by Lunar on 03/08/2022.
//

import XCTest
@testable import AirCasting

class MapDownloaderMeasurementTypeTests: XCTestCase {
    func testGettingApiName_whenAsked_shouldReturnBelowString() {
        let particulateMatter: String = MapDownloaderMeasurementType.particulateMatter.apiName
        XCTAssertEqual(particulateMatter, "Particulate Matter")
        
        let ozone: String = MapDownloaderMeasurementType.ozone.apiName
        XCTAssertEqual(ozone, "Ozone")
    }
    
    func testGettingSensorSuffixName_whenAsked_shouldReturnBelowString() {
        let particulateMatter: String = MapDownloaderMeasurementType.particulateMatter.sensorNameSuffix
        XCTAssertEqual(particulateMatter, "-pm2.5")
        
        let ozone: String = MapDownloaderMeasurementType.ozone.sensorNameSuffix
        XCTAssertEqual(ozone, "-o3")
    }
    
    func testGettingCapitalizedName_whenAsked_shouldReturnBelowString() {
        let particulateMatter: String = MapDownloaderMeasurementType.particulateMatter.capitalizedName
        XCTAssertEqual(particulateMatter, "Particulate Matter")
        
        let ozone: String = MapDownloaderMeasurementType.ozone.capitalizedName
        XCTAssertEqual(ozone, "Ozone")
    }
}
