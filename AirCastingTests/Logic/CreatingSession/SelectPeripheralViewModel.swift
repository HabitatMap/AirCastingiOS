// Created by Lunar on 17/11/2022.
//

import XCTest
@testable import AirCasting

final class SelectPeripheralViewModelTests: XCTestCase {

    func testParseAirBeamMini100NormalizesColonMacAndSubtractsTwo() {
        let parsed = BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini:A2:34:56:78:A1")
        XCTAssertEqual(parsed?.normalizedName, "AirBeamMini:A23456789F")
        XCTAssertEqual(parsed?.macAddress, "A23456789F")

        let parsedEven = BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini:A2:34:56:78:A0")
        XCTAssertEqual(parsedEven?.normalizedName, "AirBeamMini:A23456789E")
        XCTAssertEqual(parsedEven?.macAddress, "A23456789E")
    }

    func testParseAirBeamMini101PreservesCompactHexMac() {
        let parsed = BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini:A23456789E")
        XCTAssertEqual(parsed?.normalizedName, "AirBeamMini:A23456789E")
        XCTAssertEqual(parsed?.macAddress, "A23456789E")
    }

    func testParseAirBeamMiniV1AndAirBeam3PreservesName() {
        let v1Mini = BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini:a23456789e")
        XCTAssertEqual(v1Mini?.normalizedName, "AirBeamMini:a23456789e")
        XCTAssertEqual(v1Mini?.macAddress, "a23456789e")

        let ab3 = BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeam3:a23456789e")
        XCTAssertEqual(ab3?.normalizedName, "AirBeam3:a23456789e")
        XCTAssertEqual(ab3?.macAddress, "a23456789e")
    }

    func testParseBareOrInvalidNameReturnsNil() {
        XCTAssertNil(BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini"))
        XCTAssertNil(BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini:ZZZZZZZZZZZZ"))
        XCTAssertNil(BluetoothManager.parseAirBeamMiniAdvertisedName(nil))
    }
}
