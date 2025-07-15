// Created by Lunar on 14.07.25.
//


import XCTest
@testable import AirCasting

final class PartitionedTests: XCTestCase {

    func testPartitionedSplitsCorrectly() {
        let numbers = [1, 2, 3, 4, 5, 6]

        let (even, odd) = numbers.partitioned { $0 % 2 == 0 }

        XCTAssertEqual(even, [2, 4, 6], "Should contain even numbers")
        XCTAssertEqual(odd, [1, 3, 5], "Should contain odd numbers")
    }

    func testPartitionedWithEmptySequence() {
        let emptyArray: [Int] = []

        let (matching, nonMatching) = emptyArray.partitioned { $0 > 0 }

        XCTAssertTrue(matching.isEmpty)
        XCTAssertTrue(nonMatching.isEmpty)
    }

    func testPartitionedAllMatch() {
        let values = [2, 4, 6]

        let (matching, nonMatching) = values.partitioned { $0 % 2 == 0 }

        XCTAssertEqual(matching, values)
        XCTAssertTrue(nonMatching.isEmpty)
    }

    func testPartitionedNoneMatch() {
        let values = [1, 3, 5]

        let (matching, nonMatching) = values.partitioned { $0 % 2 == 0 }

        XCTAssertTrue(matching.isEmpty)
        XCTAssertEqual(nonMatching, values)
    }
}
