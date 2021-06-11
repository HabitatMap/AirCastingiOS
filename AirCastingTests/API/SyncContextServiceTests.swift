// Created by Lunar on 19/06/2021.
//

import XCTest
import Combine
@testable import AirCasting

class SyncContextServiceTests: XCTestCase {
    let validContextResponseData: Data =
        """
        {
            "download": ["UUID-TO-DOWNLOAD1", "UUID-TO-DOWNLOAD2"],
            "upload": ["UUID-TO-UPLOAD1", "UUID-TO-UPLOAD2"],
            "deleted": ["UUID-TO-DELETE1", "UUID-TO-DELETE2"],
        }
        """.data(using: .utf8)!
    let client = APIClientMock()
    let auth = RequestAuthorizationServiceMock()
    let responseValidator = HTTPResponseValidatorMock()
    lazy var service = SessionSynchronizationService(client: client, authorization: auth, responseValidator: responseValidator)
    private var cancellables: [AnyCancellable] = []
    
    func test_callsEndponitCorrectly() {
        setupWithCorrectDataReturned()
        let exp = expectation(description: "Will call correct endpoint")
        service
            .getSynchronizationContext(localSessions: .random)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTAssertEqual(self.client.callHistory.count, 1)
                let request = self.client.callHistory.first!
                XCTAssertEqual(request.url?.absoluteString, "http://aircasting.org/api/user/sessions/sync_with_versioning.json")
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.allHTTPHeaderFields?["Accept"], "application/json")
                XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
                exp.fulfill()
            })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 0.2)
    }
    
    func test_parsesDataCorrectly() {
        setupWithCorrectDataReturned()
        let exp = expectation(description: "Will parse data")
        service
            .getSynchronizationContext(localSessions: .random)
            .sink(receiveCompletion: { _ in }, receiveValue: { context in
                XCTAssertTrue(context.needToBeDownloaded ~~ ["UUID-TO-DOWNLOAD1", "UUID-TO-DOWNLOAD2"])
                XCTAssertTrue(context.needToBeUploaded ~~ ["UUID-TO-UPLOAD1", "UUID-TO-UPLOAD2"])
                XCTAssertTrue(context.removed ~~ ["UUID-TO-DELETE1", "UUID-TO-DELETE2"])
                exp.fulfill()
            })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 0.2)
    }
    
    func test_sendsCorrectJsonInBody() {
        setupWithCorrectDataReturned()
        let exp = expectation(description: "Sends correct JSON body")
        service
            .getSynchronizationContext(localSessions: [.init(uuid: "FIRST", deleted: true, version: 1), .init(uuid: "SECOND", deleted: false, version: nil)])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTAssertEqual(self.client.callHistory.count, 1)
                let request = self.client.callHistory.first!
                let json = try! JSONSerialization.jsonObject(with: request.httpBody!, options: .allowFragments) as! [String : Any]
                guard let metadataJsonString = json["data"] as? String else {
                    XCTFail("Unexpected data format!")
                    return
                }
                let metadataJson = try! JSONSerialization.jsonObject(with: metadataJsonString.data(using: .utf8)!, options: .allowFragments) as! [[String : Any]]
                XCTAssertEqual(metadataJson.count, 2)
                guard let first = metadataJson.first(where: { $0["uuid"] as? String == "FIRST" }) else {
                    XCTFail("Unexpected data format!")
                    return
                }
                guard let second = metadataJson.first(where: { $0["uuid"] as? String == "SECOND" }) else {
                    XCTFail("Unexpected data format!")
                    return
                }
                XCTAssertEqual(first["deleted"] as? Bool, true)
                XCTAssertEqual(first["version"] as? Int, 1)
                XCTAssertEqual(second["deleted"] as? Bool, false)
                XCTAssertNil(second["version"])
                exp.fulfill()
            })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 0.2)
    }
    
    // MARK: - Error handling
    
    func test_whenServerReturnsError_finishesWithError() {
        setupWithAPICallError(DummyError(errorData: "some_error"))
        let exp = expectation(description: "Will finish with error")
        service
            .getSynchronizationContext(localSessions: .random)
            .sink(receiveCompletion: { result in
                defer { exp.fulfill() }
                guard case .failure = result else { XCTFail("Expected to fail!"); return }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 0.2)
    }
    
    func test_whenServerReturnsMalformedData_finishesWithError() {
        setupWithMalformedData()
        let exp = expectation(description: "Will finish with error")
        service
            .getSynchronizationContext(localSessions: .random)
            .sink(receiveCompletion: { result in
                defer { exp.fulfill() }
                guard case .failure = result else { XCTFail("Expected to fail!"); return }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 0.2)
    }
    
    // MARK: - Fixture setup
    
    private func setupWithCorrectDataReturned() {
        client.requestTaskStub = { request, completion in
            let response: (data: Data, response: HTTPURLResponse) = (data: self.validContextResponseData, response: .success())
            // We need the client to be asynchronous, see details in implementation file.
            DispatchQueue.global().async {
                completion(.success(response), request)
            }
        }
    }
    
    private func setupWithAPICallError(_ error: Error) {
        client.requestTaskStub = { request, completion in
            // We need the client to be asynchronous, see details in implementation file.
            DispatchQueue.global().async {
                completion(.failure(error), request)
            }
        }
    }
    
    private func setupWithMalformedData() {
        client.requestTaskStub = { request, completion in
            // 1KB of zeros
            let response: (data: Data, response: HTTPURLResponse) = (data: .init(count: 1024), response: .success())
            DispatchQueue.global().async {
                completion(.success(response), request)
            }
        }
    }
}

extension Array where Element == SessionsSynchronization.Metadata {
    static var random: [Element] = [.random, .random]
}

class RequestAuthorizationServiceMock: RequestAuthorisationService {
    struct DummyError: Error {
        
    }
    
    var stubError: Error? = nil
    
    func authorise(request: inout URLRequest) throws -> URLRequest {
        if let error = stubError { throw error }
        return request
    }
}

class HTTPResponseValidatorMock: HTTPResponseValidator {
    var stubError: Error? = nil
    
    func validate(response: URLResponse, data: Data) throws {
        if let error = stubError { throw error }
    }
}

extension SessionsSynchronization.Metadata {
    static var random: SessionsSynchronization.Metadata {
        return .init(uuid: .random, deleted: false, version: 0)
    }
}
