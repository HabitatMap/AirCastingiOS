// Created by Lunar on 25/06/2021.
//

import Combine
import XCTest

extension XCTestCase {
    @discardableResult
    func awaitPublisher<P: Publisher>(_ publisher: P, timeout: TimeInterval = 1.0, file: StaticString = #file, line: UInt = #line) throws -> P.Output {
        var toReturn: Result<P.Output, Error>?
        
        let exp = expectation(description: "Waiting for publisher")
        let cancellable = publisher.sink(receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case .failure(let error): toReturn = .failure(error)
            }
            exp.fulfill()
        }, receiveValue: {
            toReturn = .success($0)
        })
        waitForExpectations(timeout: timeout)
        cancellable.cancel()
        let result = try XCTUnwrap(toReturn, "Publisher didn't emit anything!", file: file, line: line)
        return try result.get()
    }
}
