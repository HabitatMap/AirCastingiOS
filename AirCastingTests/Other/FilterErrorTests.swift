// Created by Lunar on 26/07/2021.
//

import XCTest
import Combine
@testable import AirCasting

class FilterErrorTests: XCTestCase {
    var cancellables: [AnyCancellable] = []
    
    func test_filtering_willFinishFilteredOutErrors() {
        let exp = expectation(description: "Will just finish filtered out errors")
        Just(1)
            .tryMap { _ in throw DummyError() }
            .filterError({ _ in return false })
            .sink(receiveCompletion: {
                switch $0 {
                case .failure: break
                case .finished: exp.fulfill()
                }
            }, receiveValue: {
            }).store(in: &cancellables)
        wait(for: [exp], timeout: 0.1)
    }
    
    func test_filtering_willErrorOutErrorsNotFilteredOut() {
        let exp = expectation(description: "Will throw error on not filtered errors")
        Just(1)
            .tryMap { _ in throw DummyError() }
            .filterError({ _ in return true })
            .sink(receiveCompletion: {
                switch $0 {
                case .failure: exp.fulfill()
                case .finished: break
                }
            }, receiveValue: {
            }).store(in: &cancellables)
        wait(for: [exp], timeout: 0.1)
    }
}

