// Created by Lunar on 24/04/2021.
//

import XCTest
@testable import AirCasting

final class SignInAuthorizationAPIServiceTests: APIServiceTestCase {
    private lazy var tested: AuthorizationAPIService = AuthorizationAPIService()

    func testTimeout() throws {
        client.failing(with: URLError(.timedOut))

        let input = AuthorizationAPI.SigninUserInput(username: UUID().uuidString, password: UUID().uuidString)
        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.signIn(input: input) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(AuthorizationError.timeout):
            print("Retuned valid error")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testRequestCreation() throws {
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, completion in
            receivedRequest = request
            completion(.failure(URLError(.timedOut)), request)
        }

        let input = AuthorizationAPI.SigninUserInput(username: UUID().uuidString, password: UUID().uuidString)
        tested.signIn(input: input, completion: { _ in })

        let base64input = Data("\(input.username):\(input.password)".utf8).base64EncodedString()

        let request = try XCTUnwrap(receivedRequest)
        XCTAssertEqual(request.url, URL(string: "http://aircasting.org/api/user.json")!)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        XCTAssertEqual(request.allHTTPHeaderFields, ["Accept": "application/json",
                                                     "Content-Type": "application/json",
                                                     "Authorization": "Basic \(base64input)"
        ])
    }

    func testInvalidResponse() throws {
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        client.returning((data: Data(#"{ "error": "some invalid message" }"#.utf8), response: response))
        
        let errorContent = "ASD"
        validator.stubError = DummyError(errorData: errorContent)

        let input = AuthorizationAPI.SigninUserInput(username: UUID().uuidString, password: UUID().uuidString)
        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.signIn(input: input) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(AuthorizationError.other):
            print("Retuned valid error \(String(describing: result))")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testSuccessfulSampleFileResponse() throws {
        let data = Data("""
            {
                "id": 235235,
                "username": "john doe",
                "email": "john@doe.pl",
                "authentication_token": "rwerwewt34543534534543",
                "session_stopped_alert": false
            }
            """.utf8)
        client.returning((data: data, response: .success()))

        let input = AuthorizationAPI.SigninUserInput(username: UUID().uuidString, password: UUID().uuidString)
        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.signIn(input: input) {
            result = $0
        }

        let response =  try XCTUnwrap(result).get()

        let expectedResponse = AuthorizationAPI.UserProfile(id: 235235, authentication_token: "rwerwewt34543534534543", username: "john doe", email: "john@doe.pl")
        XCTAssertEqual(expectedResponse, response)
    }
}

final class CreateAccountAuthorizationAPIServiceTests: APIServiceTestCase {
    private lazy var tested: AuthorizationAPIService = AuthorizationAPIService()
    private lazy var input: AuthorizationAPI.SignupUserInput = AuthorizationAPI.SignupUserInput(
        email: UUID().uuidString + "@do.com",
        username: UUID().uuidString,
        password: UUID().uuidString,
        send_emails: .random())

    func testTimeout() throws {
        client.failing(with: URLError(.timedOut))

        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.createAccount(input: input) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(AuthorizationError.timeout):
            print("Retuned valid error")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testRequestCreation() throws {
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, completion in
            receivedRequest = request
            completion(.failure(URLError(.timedOut)), request)
        }

        tested.createAccount(input: input, completion: { _ in })

        struct SignupAPIInput: Encodable, Hashable {
            let user: AuthorizationAPI.SignupUserInput
        }

        let body = try JSONEncoder().encode(SignupAPIInput(user: input))

        let request = try XCTUnwrap(receivedRequest)
        XCTAssertEqual(request.url, URL(string: "http://aircasting.org/api/user.json")!)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, body)
        XCTAssertEqual(request.allHTTPHeaderFields, ["Accept": "application/json",
                                                     "Content-Type": "application/json"])
    }

    func testInvalidResponse() throws {
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        client.returning((data: Data(#"{ "error": "some invalid message" }"#.utf8), response: response))

        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.createAccount(input: input) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(AuthorizationError.other):
            print("Retuned valid error \(String(describing: result))")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testSuccessfulSampleFileResponse() throws {
        let data = Data("""
            {
            "id": 3424523,
            "email": "m+1@m.pl",
            "authentication_token": "wer3r3434344334r",
            "username": "John doe",
            "session_stopped_alert": false
            }

            """.utf8)
        client.returning((data: data, response: .success()))

        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.createAccount(input: input) {
            result = $0
        }

        let response = try XCTUnwrap(result).get()

        let expectedResponse = AuthorizationAPI.UserProfile(id: 3424523, authentication_token: "wer3r3434344334r", username: "John doe", email: "m+1@m.pl")
        XCTAssertEqual(expectedResponse, response)
    }

    func testUsernameTakenError() throws {
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 422, httpVersion: nil, headerFields: nil)!
        client.returning((data: Data(#"{"username": ["has already been taken"] }"#.utf8), response: response))

        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.createAccount(input: input) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(AuthorizationError.usernameTaken):
            print("Retuned valid error \(String(describing: result))")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testEmailTakenError() throws {
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 422, httpVersion: nil, headerFields: nil)!
        client.returning((data: Data(#"{"email": ["has already been taken"] }"#.utf8), response: response))

        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.createAccount(input: input) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(AuthorizationError.emailTaken):
            print("Retuned valid error \(String(describing: result))")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testEmailAndUsernameTakenError() throws {
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 422, httpVersion: nil, headerFields: nil)!
        client.returning((data: Data(#"{"email": ["has already been taken"], "username": ["has already been taken"] }"#.utf8), response: response))

        var result: Result<AuthorizationAPI.UserProfile, AuthorizationError>?
        tested.createAccount(input: input) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(AuthorizationError.emailTaken):
            print("Retuned valid error \(String(describing: result))")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }
}
