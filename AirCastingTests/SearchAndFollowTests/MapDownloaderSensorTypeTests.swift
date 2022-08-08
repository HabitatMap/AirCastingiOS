// Created by Lunar on 03/08/2022.
//

import XCTest
@testable import AirCasting

class MapDownloaderSensorTypeTests: XCTestCase {
    func test_gettingSensorNamePrefix_returnsCorrectString() {
        let airbeam: String = MapDownloaderSensorType.AB3and2.sensorNamePrefix
        XCTAssertEqual(airbeam, "airbeam")
        
        let openAQ: String = MapDownloaderSensorType.OpenAQ.sensorNamePrefix
        XCTAssertEqual(openAQ, "openaq")
        
        let purpleAir: String = MapDownloaderSensorType.PurpleAir.sensorNamePrefix
        XCTAssertEqual(purpleAir, "purpleair")
    }
    
    func test_gettingCapitalizedName_returnCorrectString() {
        let airbeam: String = MapDownloaderSensorType.AB3and2.capitalizedName
        XCTAssertEqual(airbeam, "AirBeam")
        
        let openAQ: String = MapDownloaderSensorType.OpenAQ.capitalizedName
        XCTAssertEqual(openAQ, "OpenAQ")
        
        let purpleAir: String = MapDownloaderSensorType.PurpleAir.capitalizedName
        XCTAssertEqual(purpleAir, "PurpleAir")
    }
}
