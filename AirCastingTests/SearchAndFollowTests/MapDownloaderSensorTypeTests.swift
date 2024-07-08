// Created by Lunar on 03/08/2022.
//

import XCTest
@testable import AirCasting

class MapDownloaderSensorTypeTests: XCTestCase {
    func test_gettingSensorNamePrefix_returnsCorrectString() {
        let airbeam: String = MapDownloaderSensorType.AirBeam.sensorNamePrefix
        XCTAssertEqual(airbeam, "airbeam")
        
        let govt: String = MapDownloaderSensorType.Govt.sensorNamePrefix
        XCTAssertEqual(govt, "government")
    }
    
    func test_gettingCapitalizedName_returnCorrectString() {
        let airbeam: String = MapDownloaderSensorType.AirBeam.capitalizedName
        XCTAssertEqual(airbeam, "AirBeam")
        
        let govt: String = MapDownloaderSensorType.Govt.capitalizedName
        XCTAssertEqual(govt, "Govt")
    }
}
