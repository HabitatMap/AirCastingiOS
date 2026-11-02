// Created by Lunar on 17/11/2022.
//

import XCTest
@testable import AirCasting

final class SelectPeripheralViewModel: XCTestCase {

    func testParseOldV2AdvertisedNameNormalizesMacAndSubtractsTwo() throws {
        let parsed = try XCTUnwrap(
            BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini:24:58:7C:AC:A6:B6")
        )
        XCTAssertEqual(parsed.normalizedName, "AirBeamMini:24587CACA6B4")
        XCTAssertEqual(parsed.macAddress, "24587CACA6B4")
    }

    func testParseOldV2AdvertisedNamePreservesLeadingZerosAndHandlesByteBorrow() throws {
        let parsedLeadingZero = try XCTUnwrap(
            BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini:00:18:96:10:70:00")
        )
        XCTAssertEqual(parsedLeadingZero.normalizedName, "AirBeamMini:001896106FFE")
        XCTAssertEqual(parsedLeadingZero.macAddress, "001896106FFE")
    }

    func testParseNewV2AdvertisedNameKeepsSingleColonNameAndExtractsMac() throws {
        let parsed = try XCTUnwrap(
            BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeamMini:24587CACA6B4")
        )
        XCTAssertEqual(parsed.normalizedName, "AirBeamMini:24587CACA6B4")
        XCTAssertEqual(parsed.macAddress, "24587CACA6B4")
    }

    func testParseOtherAirBeamReturnsNil() {
        XCTAssertNil(BluetoothManager.parseAirBeamMiniAdvertisedName("AirBeam3:0018961070D6"))
        XCTAssertNil(BluetoothManager.parseAirBeamMiniAdvertisedName("airbeammini"))
        XCTAssertNil(BluetoothManager.parseAirBeamMiniAdvertisedName(nil))
    }
}
