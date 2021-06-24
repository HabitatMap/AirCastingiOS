// Created by Lunar on 16/06/2021.
//

import XCTest
import Combine
@testable import AirCasting

class LogErrorPublisherTests: XCTestCase {
    private var cancellables: [AnyCancellable] = []
    
    func testLogsError() {
        let array = [0, 1, 2, 3, 4, 5, 6]
        var allValues: [Int] = []
        var errorPrinted: String?
        var errorReturned: Error?
        
        let exp = expectation(description: "Waiting for publisher")
        array
            .publisher
            .tryFilter {
                if $0 == 4 { throw DummyError(errorData: "TEST ERROR") }
                return true
            }
            .logError(message: "Test prefix", logFunc: { errorPrinted = $0 })
            .sink { result in
                if case .failure(let error) = result { errorReturned = error }
                exp.fulfill()
            } receiveValue: { allValues.append($0) }
            .store(in: &cancellables)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(errorPrinted, "Test prefix: TEST ERROR")
        XCTAssertTrue(errorReturned is DummyError)
        XCTAssertEqual(allValues, [0, 1, 2, 3])
    }
}

class LogErrorAndContinuePublisherTests: XCTestCase {
    private var cancellables: [AnyCancellable] = []
    
    func testLogsError() {
        let array = [0, 1, 2, 3, 4, 5, 6]
        var allValues: [Int] = []
        var errorPrinted: String?
        var errorReturned: Error?
        var finishedEventReceived: Bool = false
        
        let exp = expectation(description: "Waiting for publisher")
        array
            .publisher
            .tryFilter {
                if $0 == 4 { throw DummyError(errorData: "TEST ERROR") }
                return true
            }
            .logErrorAndComplete(message: "Test prefix", logFunc: { errorPrinted = $0 })
            .sink { result in
                if case .failure(let error) = result { errorReturned = error } else {
                    finishedEventReceived = true
                }
                exp.fulfill()
            } receiveValue: { allValues.append($0) }
            .store(in: &cancellables)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(errorPrinted, "Test prefix: TEST ERROR")
        XCTAssertNil(errorReturned)
        XCTAssertTrue(finishedEventReceived)
        XCTAssertEqual(allValues, [0, 1, 2, 3])
    }
}
