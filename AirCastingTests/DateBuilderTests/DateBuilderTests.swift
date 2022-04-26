// Created by Lunar on 03/03/2022.
//

import XCTest
@testable import AirCasting

final class DateBuilderTests: XCTestCase {
    private let formatter = DateFormatter()

    override func setUp() {
        formatter.timeZone = TimeZone.utc
        formatter.dateFormat = "HH:mm"
    }
    
    func test_beginingOfDay() {
        let beginingInSeconds =  DateBuilder.getFakeUTCDate().beginingOfDayInSeconds
        let currentTime = formatter.string(from:  Date(timeIntervalSince1970: beginingInSeconds))
        XCTAssertEqual(currentTime, "00:00")
    }
    
    func test_endOfTheDay() {
        let endInSeconds =         DateBuilder.getFakeUTCDate().endOfDayInSeconds
        let currentTime = formatter.string(from:  Date(timeIntervalSince1970: endInSeconds))
        XCTAssertEqual(currentTime, "23:59")
    }
}
