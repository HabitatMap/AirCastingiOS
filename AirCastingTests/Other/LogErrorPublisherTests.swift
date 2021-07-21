// Created by Lunar on 16/06/2021.
//

import XCTest
import Combine
@testable import AirCasting

struct LogFuncParameters {
    let message: String
    let file: String
    let function: String
    let line: Int
}

class LogErrorPublisherTests: XCTestCase {
    private var cancellables: [AnyCancellable] = []
    
    func testLogsError() throws {
        let array = [0, 1, 2, 3, 4, 5, 6]
        var allValues: [Int] = []
        var logPrinted: LogFuncParameters?
        var errorReturned: Error?
        
        let exp = expectation(description: "Waiting for publisher")
        array
            .publisher
            .tryFilter {
                if $0 == 4 { throw LocalizedErrorStub(string: "TEST ERROR") }
                return true
            }
            .logError(message: "Test prefix", logFunc: { logPrinted = .init(message: $0, file: $1, function: $2, line: $3) })
            .sink { result in
                if case .failure(let error) = result { errorReturned = error }
                exp.fulfill()
            } receiveValue: { allValues.append($0) }
            .store(in: &cancellables)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(logPrinted?.message, "Test prefix: TEST ERROR")
        XCTAssertEqual(logPrinted?.function, #function)
        XCTAssertTrue(errorReturned is LocalizedErrorStub)
        XCTAssertEqual(allValues, [0, 1, 2, 3])
        // NOTE: Those will break if stuff changes
        let filePathString = try XCTUnwrap(logPrinted?.file)
        let file = URL(fileURLWithPath: filePathString).lastPathComponent
        XCTAssertEqual(file, "LogErrorPublisherTests.swift")
        XCTAssertEqual(logPrinted?.line, 31)
        
    }
}

class LogErrorAndContinuePublisherTests: XCTestCase {
    private var cancellables: [AnyCancellable] = []
    
    func testLogsError() throws {
        let array = [0, 1, 2, 3, 4, 5, 6]
        var allValues: [Int] = []
        var logPrinted: LogFuncParameters?
        var errorReturned: Error?
        var finishedEventReceived: Bool = false
        
        let exp = expectation(description: "Waiting for publisher")
        array
            .publisher
            .tryFilter {
                if $0 == 4 { throw LocalizedErrorStub(string: "TEST ERROR") }
                return true
            }
            .logErrorAndComplete(message: "Test prefix", logFunc: { logPrinted = .init(message: $0, file: $1, function: $2, line: $3) })
            .sink { result in
                if case .failure(let error) = result { errorReturned = error } else {
                    finishedEventReceived = true
                }
                exp.fulfill()
            } receiveValue: { allValues.append($0) }
            .store(in: &cancellables)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(logPrinted?.message, "Test prefix: TEST ERROR")
        XCTAssertEqual(logPrinted?.function, #function)
        XCTAssertNil(errorReturned)
        XCTAssertTrue(finishedEventReceived)
        XCTAssertEqual(allValues, [0, 1, 2, 3])
        // NOTE: Those will break if stuff changes
        let filePathString = try XCTUnwrap(logPrinted?.file)
        let file = URL(fileURLWithPath: filePathString).lastPathComponent
        XCTAssertEqual(file, "LogErrorPublisherTests.swift")
        XCTAssertEqual(logPrinted?.line, 69)
    }
}
