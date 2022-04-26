// Created by Lunar on 14/06/2021.
//

@testable import AirCasting
import XCTest

final class ArrayCountElementsTests: ACTestCase {
    func testWhenNoSuchItemFound_returnsZero() {
        let array = [0,1,2,3,4]
        XCTAssertEqual(array.count(of: 5), 0)
    }
    
    func testWhenItemIsPresent_returnsNumberOfRepetitions() {
        let array = [0,1,2,3,4,3,5,2,6,3]
        XCTAssertEqual(array.count(of: 3), 3)
    }
    
    func testEmptyArray_returnsZero() {
        let array: [Int] = []
        XCTAssertEqual(array.count(of: 5), 0)
    }
}


final class ArrayContainsSameElementsTests: ACTestCase {
    func testNonRepeatingContainment_returnsTrueIfEqual() {
        let array1 = [0,1,2,3,4,5]
        let array2 = [2,3,0,4,1,5]
        XCTAssertTrue(array1.containsSameElements(as: array2))
        XCTAssertTrue(array2.containsSameElements(as: array1))
    }
    
    func testExactlyTheSameArrays_returnsTrue() {
        let array1 = [8,8,8,8,8,8,8,8,8]
        let array2 = [8,8,8,8,8,8,8,8,8]
        XCTAssertTrue(array1.containsSameElements(as: array2))
        XCTAssertTrue(array2.containsSameElements(as: array1))
    }
    
    func testNonRepeatingContainment_returnsFalseIfDifferent() {
        let array1 = [0,1,2,3,4,8]
        let array2 = [2,3,0,4,1,5]
        XCTAssertFalse(array1.containsSameElements(as: array2))
        XCTAssertFalse(array2.containsSameElements(as: array1))
    }
    
    func testRepeatingContainment_retunsTrueIfEqual() {
        let array1 = [0,0,1,2,3,4,5]
        let array2 = [2,3,0,4,1,5,0]
        XCTAssertTrue(array1.containsSameElements(as: array2))
        XCTAssertTrue(array2.containsSameElements(as: array1))
    }
    
    func testRepeatingContainment_retunsFalseWhenOtherElementRepeats() {
        let array1 = [0,0,1,2,3,4,5]
        let array2 = [2,3,0,4,1,5,1]
        XCTAssertFalse(array1.containsSameElements(as: array2))
        XCTAssertFalse(array2.containsSameElements(as: array1))
    }
    
    func testEmptyArrays() {
        let array1 = [0,0,1,2,3,4,5]
        let array2: [Int] = []
        XCTAssertFalse(array1.containsSameElements(as: array2))
        XCTAssertFalse(array2.containsSameElements(as: array1))
    }
}

final class ArrayCreatingTimesTests: ACTestCase {
    class ExampleClass { }
    
    func testCreatingArray_containsCorrectNumberOfElements() {
        let array = [ExampleClass](creating: ExampleClass(), times: 42)
        XCTAssertEqual(array.count, 42)
    }
    
    func testCreatingArray_createsNewObjectsEachTime() {
        let array = [ExampleClass](creating: ExampleClass(), times: 2)
        XCTAssertTrue(array[0] !== array[1])
    }
}
