// Created by Lunar on 03/08/2022.
//

import XCTest
@testable import AirCasting

class MapDownloaderUnitSymbolTests: XCTestCase {
    func testGettingName_whenAsked_shouldReturnBelowString() {
        let uqm3: String = MapDownloaderUnitSymbol.uqm3.name
        XCTAssertEqual(uqm3, "µg/m³")
        
        let ppb: String = MapDownloaderUnitSymbol.ppb.name
        XCTAssertEqual(ppb, "ppb")
    }
}
