// Created by Lunar on 25/06/2021.
//

import XCTest
@testable import AirCasting

extension XCTestCase {
    func assertContainsSameElements<Element>(_ array1: Array<Element>, _ array2: Array<Element>, file: StaticString = #file, line: UInt = #line) where Element: Equatable{
        guard array1.containsSameElements(as: array2) else {
            XCTFail("Expected arrays to contain the same elements! Array 1: \(array1), Array 2: \(array2)")
            return
        }
    }
}
