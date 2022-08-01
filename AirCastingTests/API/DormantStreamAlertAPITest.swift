// Created by Lunar on 01/08/2022.
//

import XCTest
@testable import AirCasting

class DormantStreamAlertAPITest: APIServiceTestCase {
    lazy var sut = DormantStreamAlertAPI()

    func test_whenSendsRequest_hasCorrectURL() throws {
            var receivedRequest: URLRequest?
            client.requestTaskStub = { request, completion in
                receivedRequest = request
                completion(.failure(URLError(.timedOut)), request)
            }
        
            sut.sendNewSetting(value: true, completion: { _ in })

            let request = try XCTUnwrap(receivedRequest)
            XCTAssertEqual(request.url, URL(string: "http://aircasting.org/api/user/settings")!)
        }

    func test_whenSendsRequest_usesPOSTMethod() throws {
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, completion in
            receivedRequest = request
            completion(.failure(URLError(.timedOut)), request)
        }
        
        sut.sendNewSetting(value: true, completion: { _ in })
        let request = try XCTUnwrap(receivedRequest)
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func test_whenSendsRequestwithTrueValue_hasCorrectBody() throws {
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, completion in
            receivedRequest = request
            completion(.failure(URLError(.timedOut)), request)
        }
        
        sut.sendNewSetting(value: true, completion: { _ in })
        let body = try XCTUnwrap(receivedRequest?.httpBody)
        let expectedBody = "{\"data\":{\"session_stopped_alert\":\"true\"}}"
        
        XCTAssertEqual(String(data: body, encoding: .utf8), expectedBody)
    }
    
    func test_whenSendsRequestWithFalseValue_hasCorrectBody() throws {
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, completion in
            receivedRequest = request
            completion(.failure(URLError(.timedOut)), request)
        }
        
        sut.sendNewSetting(value: false, completion: { _ in })
        let body = try XCTUnwrap(receivedRequest?.httpBody)
        let expectedBody = "{\"data\":{\"session_stopped_alert\":\"false\"}}"
        
        XCTAssertEqual(String(data: body, encoding: .utf8), expectedBody)
    }
}
