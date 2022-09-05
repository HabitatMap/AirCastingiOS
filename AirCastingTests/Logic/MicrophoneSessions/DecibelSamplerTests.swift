// Created by Lunar on 30/06/2022.
//

import Foundation
import XCTest
@testable import AirCasting

class DecibelSamplerTests: XCTestCase {
    let microphone = MicrophoneMock()
    lazy var sut = DecibelSampler(microphone: microphone)
    
    func test_whenMicrophoneIsNotRecoring_itStartsIt() {
        microphone.state = .notRecording
        sut.sample { _ in }
        XCTAssertEqual(microphone.callHistory.first, .start)
    }
    
    func test_whenDBLevelRetrieved_itCallsCompletion() {
        let expectation = expectation(description: "whenDBLevelRetrieved_itCallsCompletion")
        let level = 50.0
        microphone.stubbedLevel = level
        sut.sample { result in
            do {
                let receivedLevel = try result.get()
                XCTAssertEqual(receivedLevel, level)
            }
            catch { XCTFail("Unexpected failure while sampling") }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    func test_whenDBLevelIsNil_itCallsCompletionWithFailure() {
        let expectation = expectation(description: "whenDBLevelIsNil_itCallsCompletionWithFailure")
        microphone.stubbedLevel = nil
        sut.sample { result in
            do { _ = try result.get(); XCTFail("Expected to throw an error") }
            catch { }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    func test_whenMicophoneIsInterrupted_callsCompletionWithFailure() {
        let expectation = expectation(description: "whenMicophoneIsInterrupted_callsCompletionWithFailure")
        microphone.state = .interrupted
        sut.sample { result in
            do { _ = try result.get(); XCTFail("Expected to throw an error") }
            catch _ as LevelSamplerError { }
            catch { XCTFail("Invalid error type for microphone interrupted state") }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    func test_onDeinit_stopsMicrophone() throws {
        let microphone = MicrophoneMock()
        let _: DecibelSampler? = DecibelSampler(microphone: microphone)
        XCTAssertEqual(microphone.callHistory.last, .stop)
    }
}
