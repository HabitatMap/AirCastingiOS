// Created by Lunar on 19/06/2021.
//

import XCTest
import Combine
@testable import AirCasting

final class SyncContextServiceTests: APIServiceTestCase {
    private let validContextResponseData: Data =
        """
        {
            "download": ["UUID-TO-DOWNLOAD1", "UUID-TO-DOWNLOAD2"],
            "upload": ["UUID-TO-UPLOAD1", "UUID-TO-UPLOAD2"],
            "deleted": ["UUID-TO-DELETE1", "UUID-TO-DELETE2"],
        }
        """.data(using: .utf8)!
    private lazy var service = SessionSynchronizationService()
    private var cancellables: [AnyCancellable] = []
    
    override func tearDown() {
        super.tearDown()
        cancellables = []
    }
    
    func test_callsEndponitCorrectly() throws {
        setupWithCorrectDataReturned()
        
        try awaitPublisher(service.getSynchronizationContext(localSessions: .random))
        
        XCTAssertEqual(self.client.callHistory.count, 1)
        let request = self.client.callHistory.first!
        XCTAssertEqual(request.url?.absoluteString, "http://aircasting.org/api/user/sessions/sync_with_versioning.json")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.allHTTPHeaderFields?["Accept"], "application/json")
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
    }
    
    func test_parsesDataCorrectly() throws {
        setupWithCorrectDataReturned()
        
        let context = try awaitPublisher(service.getSynchronizationContext(localSessions: .random))
        
        assertContainsSameElements(context.needToBeDownloaded, ["UUID-TO-DOWNLOAD1", "UUID-TO-DOWNLOAD2"])
        assertContainsSameElements(context.needToBeUploaded, ["UUID-TO-UPLOAD1", "UUID-TO-UPLOAD2"])
        assertContainsSameElements(context.removed, ["UUID-TO-DELETE1", "UUID-TO-DELETE2"])
    }
    
    func test_sendsCorrectJsonInBody() throws {
        setupWithCorrectDataReturned()
        
        let context: [SessionsSynchronization.Metadata] = [.init(uuid: "FIRST", deleted: true, version: 1), .init(uuid: "SECOND", deleted: false, version: nil)]
        try awaitPublisher(service.getSynchronizationContext(localSessions: context))
        
        XCTAssertEqual(self.client.callHistory.count, 1)
        let request = self.client.callHistory.first!
        let json = try! JSONSerialization.jsonObject(with: request.httpBody!, options: .allowFragments) as! [String : Any]
        guard let metadataJsonString = json["data"] as? String else {
            XCTFail("Unexpected data format!"); return
        }
        let metadataJson = try! JSONSerialization.jsonObject(with: metadataJsonString.data(using: .utf8)!, options: .allowFragments) as! [[String : Any]]
        XCTAssertEqual(metadataJson.count, 2)
        guard let first = metadataJson.first(where: { $0["uuid"] as? String == "FIRST" }) else {
            XCTFail("Unexpected data format!"); return
        }
        guard let second = metadataJson.first(where: { $0["uuid"] as? String == "SECOND" }) else {
            XCTFail("Unexpected data format!"); return
        }
        XCTAssertEqual(first["deleted"] as? Bool, true)
        XCTAssertEqual(first["version"] as? Int, 1)
        XCTAssertEqual(second["deleted"] as? Bool, false)
        XCTAssertNil(second["version"])
    }
    
    // MARK: - Error handling
    
    func test_whenServerReturnsError_finishesWithError() {
        setupWithAPICallError(DummyError())
        
        XCTAssertThrowsError(try awaitPublisher(service.getSynchronizationContext(localSessions: .random)))
    }
    
    func test_whenServerReturnsMalformedData_finishesWithError() {
        setupWithMalformedData()
        
        XCTAssertThrowsError(try awaitPublisher(service.getSynchronizationContext(localSessions: .random)))
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

extension SessionsSynchronization.Metadata {
    static var random: SessionsSynchronization.Metadata {
        return .init(uuid: .random, deleted: false, version: 0)
    }
}
