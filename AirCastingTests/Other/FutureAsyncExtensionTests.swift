import XCTest
import Combine
@testable import AirCasting

class FutureAsyncExtensionTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testAsyncOperationSuccess_WithVoidReturn() {
        // Given
        let expectation = XCTestExpectation(description: "Future should complete successfully")
        var completionCalled = false
        
        // When
        let future = Future<Void, Error> {
            // Simulate async operation that succeeds
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            return ()
        }
        
        // Then
        future
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        completionCalled = true
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { _ in
                    // Value received for Void type
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(completionCalled)
    }
    
    func testAsyncOperationSuccess_WithStringReturn() {
        // Given
        let expectation = XCTestExpectation(description: "Future should return string value")
        let expectedValue = "Hello, World!"
        var receivedValue: String?
        
        // When
        let future = Future<String, Error> {
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            return expectedValue
        }
        
        // Then
        future
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { value in
                    receivedValue = value
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, expectedValue)
    }
    
    func testAsyncOperationSuccess_WithIntReturn() {
        // Given
        let expectation = XCTestExpectation(description: "Future should return int value")
        let expectedValue = 42
        var receivedValue: Int?
        
        // When
        let future = Future<Int, Error> {
            try await Task.sleep(nanoseconds: 30_000_000) // 0.03 seconds
            return expectedValue
        }
        
        // Then
        future
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { value in
                    receivedValue = value
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, expectedValue)
    }
    
    func testAsyncOperationSuccess_WithComplexObjectReturn() {
        // Given
        struct TestData: Equatable {
            let id: Int
            let name: String
        }
        
        let expectation = XCTestExpectation(description: "Future should return complex object")
        let expectedValue = TestData(id: 1, name: "Test")
        var receivedValue: TestData?
        
        // When
        let future = Future<TestData, Error> {
            try await Task.sleep(nanoseconds: 20_000_000) // 0.02 seconds
            return expectedValue
        }
        
        // Then
        future
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { value in
                    receivedValue = value
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, expectedValue)
    }
    
    // MARK: - Failure Cases
    
    func testAsyncOperationFailure_WithCustomError() {
        // Given
        enum TestError: Error, Equatable {
            case customError
        }
        
        let expectation = XCTestExpectation(description: "Future should fail with custom error")
        var receivedError: Error?
        
        // When
        let future = Future<String, Error> {
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            throw TestError.customError
        }
        
        // Then
        future
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Expected failure but got success")
                    case .failure(let error):
                        receivedError = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value on failure")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedError is TestError)
        XCTAssertEqual(receivedError as? TestError, TestError.customError)
    }
    
    func testAsyncOperationFailure_WithNSError() {
        // Given
        let expectation = XCTestExpectation(description: "Future should fail with NSError")
        let expectedError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        var receivedError: Error?
        
        // When
        let future = Future<Int, Error> {
            try await Task.sleep(nanoseconds: 30_000_000) // 0.03 seconds
            throw expectedError
        }
        
        // Then
        future
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Expected failure but got success")
                    case .failure(let error):
                        receivedError = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value on failure")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "TestDomain")
        XCTAssertEqual((receivedError as NSError?)?.code, 123)
    }
    
    // MARK: - Cancellation Tests
    
    func testAsyncOperationCancellation() {
        // Given
        let expectation = XCTestExpectation(description: "Future should handle cancellation")
        expectation.isInverted = true // We expect this NOT to be fulfilled
        
        // When
        let future = Future<String, Error> {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            return "Should not reach here"
        }
        
        let cancellable = future
            .sink(
                receiveCompletion: { completion in
                    expectation.fulfill() // Should not be called due to cancellation
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value after cancellation")
                }
            )
        
        // Cancel after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cancellable.cancel()
        }
        
        // Then
        wait(for: [expectation], timeout: 0.5)
    }
    
    // MARK: - Performance Tests
    
    func testAsyncOperationPerformance() {
        // Given
        let expectation = XCTestExpectation(description: "Future should complete within reasonable time")
        expectation.expectedFulfillmentCount = 100
        
        // When
        measure {
            for _ in 0..<100 {
                let future = Future<Int, Error> {
                    return 42
                }
                
                future
                    .sink(
                        receiveCompletion: { _ in
                            expectation.fulfill()
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Chaining Tests
    
    func testAsyncOperationChaining() {
        // Given
        let expectation = XCTestExpectation(description: "Chained futures should work correctly")
        let expectedFinalValue = "Processed: 42"
        var receivedValue: String?
        
        // When
        let future1 = Future<Int, Error> {
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            return 42
        }
        
        let future2 = Future<String, Error> {
            try await Task.sleep(nanoseconds: 30_000_000) // 0.03 seconds
            return "Processed: "
        }
        
        // Then
        future1
            .flatMap { value in
                future2.map { prefix in
                    "\(prefix)\(value)"
                }
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { value in
                    receivedValue = value
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, expectedFinalValue)
    }
}
