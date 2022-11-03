// Created by Lunar on 10/04/2021.
//

import Foundation
import Combine
import XCTest

extension XCTestCase {
    /// Helper method to simplify publishers check
    ///
    /// ```
    /// func testIdentifyingUsernames() throws {
    ///     let tokenizer = Tokenizer()
    ///     let tokens = try awaitPublisherResult(tokenizer.tokenize("Hello @john")).get()
    ///     XCTAssertEqual(tokens, [.text("Hello "), .username("john")])
    /// }
    /// ```
    /// - parameters:
    ///     - publisher: tested publisher
    ///     - timeout: timeout in which the await will wait
    ///     - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
    ///     - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
    /// - returns: Publishers response flattened in form of Result
    /// - throws:
    ///  https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code/
    func awaitPublisherResult<T: Publisher>(_ publisher: T, timeout: TimeInterval = 10, file: StaticString = #file, line: UInt = #line) throws -> Result<T.Output, T.Failure> {
        // This time, we use Swift's Result type to keep track of the result of our Combine pipeline:
        var result: Result<T.Output, T.Failure>?
        let expectation = self.expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error): result = .failure(error)
            case .finished: break
            }
            expectation.fulfill()
        }, receiveValue: { value in
            result = .success(value)
        })

        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        return try XCTUnwrap(result, "Awaited publisher did not produce any output", file: file, line: line)
    }
}
