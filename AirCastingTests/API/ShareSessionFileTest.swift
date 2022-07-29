// Created by Lunar on 27/07/2022.
//

import XCTest
@testable import AirCasting

class ShareSessionFileTest: APIServiceTestCase {
    lazy var sut = ShareSessionApi()

    func test_whenSendsRequest_hasCorrectURL() throws {
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, completion in
            receivedRequest = request
            completion(.failure(URLError(.timedOut)), request)
        }
        
        let email = "test@test.com"
        let uuid = UUID().uuidString
        sut.sendSession(email: email, uuid: uuid, completion: { _ in })

        let request = try XCTUnwrap(receivedRequest)
        XCTAssertEqual(request.url, URL(string: "http://aircasting.org/api/sessions/export_by_uuid.json?email=\(email)&uuid=\(uuid)")!)
    }
    
    func test_whenSendsRequest_usesGETMethod() throws {
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, completion in
            receivedRequest = request
            completion(.failure(URLError(.timedOut)), request)
        }
        
        let email = "test@test.com"
        let uuid = UUID().uuidString
        sut.sendSession(email: email, uuid: uuid, completion: { _ in })

        let request = try XCTUnwrap(receivedRequest)
        XCTAssertEqual(request.httpMethod, "GET")
    }
}
