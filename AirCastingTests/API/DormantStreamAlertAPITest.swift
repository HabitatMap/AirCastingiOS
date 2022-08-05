// Created by Lunar on 01/08/2022.
//

import XCTest
@testable import AirCasting

class DormantStreamAlertAPITest: APIServiceTestCase {
    lazy var sut = DefaultDormantStreamAlertAPI()
    
    func test_whenSendsRequest_hasCorrectURL() throws {
        let receivedRequest = captureRequestForSendingNewSetting(value: false)
        let request = try XCTUnwrap(receivedRequest)
        XCTAssertEqual(request.url, URL(string: "http://aircasting.org/api/user/settings")!)
    }
    
    func test_whenSendsRequest_usesPOSTMethod() throws {
        let receivedRequest = captureRequestForSendingNewSetting(value: false)
        let request = try XCTUnwrap(receivedRequest)
        XCTAssertEqual(request.httpMethod, "POST")
    }
    
    func test_whenSendsRequestWithTrueValue_hasCorrectBody() throws {
        let receivedRequest = captureRequestForSendingNewSetting(value: true)
        let body = try XCTUnwrap(receivedRequest?.httpBody)
        let expectedBody = "{\"data\":{\"session_stopped_alert\":\"true\"}}"
        
        XCTAssertEqual(String(data: body, encoding: .utf8), expectedBody)
    }
    
    func test_whenSendsRequestWithFalseValue_hasCorrectBody() throws {
        let receivedRequest = captureRequestForSendingNewSetting(value: false)
        let body = try XCTUnwrap(receivedRequest?.httpBody)
        let expectedBody = "{\"data\":{\"session_stopped_alert\":\"false\"}}"
        
        XCTAssertEqual(String(data: body, encoding: .utf8), expectedBody)
    }
    
    func test_whenSendsRequestThatFails_callsCompletionWithFailure() throws {
        client.requestTaskStub = { request, completion in
            completion(.failure(URLError(.timedOut)), request)
        }
        
        var completionCheck = 0
        
        sut.sendNewSetting(value: true, completion: { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                completionCheck += 1
            }
        })
        
        XCTAssertEqual(1, completionCheck)
    }
    
    func test_whenSendsRequestWithSuccess_callsCompletionWithSuccess() throws {
        client.requestTaskStub = { request, completion in
            completion(.success((data: Data(#"{ "action": "success" }"#.utf8), response: HTTPURLResponse())), request)
        }
        
        var completionCheck = 0
        
        sut.sendNewSetting(value: true, completion: { result in
            switch result {
            case .success(_):
                completionCheck += 1
            case .failure(_):
                XCTFail()
            }
        })
        
        XCTAssertEqual(1, completionCheck)
    }
    
    private func captureRequestForSendingNewSetting(value: Bool) -> URLRequest? {
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, _ in
            receivedRequest = request
        }
        sut.sendNewSetting(value: value, completion: { _ in })
        return receivedRequest
    }
}
