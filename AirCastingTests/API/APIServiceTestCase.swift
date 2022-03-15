// Created by Lunar on 06/03/2022.
//

import XCTest
import Resolver
@testable import AirCasting

class APIServiceTestCase: ACTestCase {
    let client: APIClientMock = APIClientMock()
    let authorization: AuthorisationServiceMock = AuthorisationServiceMock()
    let urlProvider = DummyURLProvider()
    let validator = HTTPResponseValidatorMock()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.authorization as RequestAuthorisationService }
        Resolver.test.register { self.client as APIClient }
        Resolver.test.register { self.urlProvider as URLProvider }
        Resolver.test.register { self.validator as HTTPResponseValidator }
    }
}

class RequestAuthorizationServiceMock: RequestAuthorisationService {
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

class URLProviderMock: URLProvider {
    var baseAppURL: URL
    
    init(baseAppURL: URL) {
        self.baseAppURL = baseAppURL
    }
}

final class AuthorisationServiceMock: RequestAuthorisationService {
    var authoriseStub: ((_ request: URLRequest) throws -> URLRequest)

    init(authoriseStub: @escaping (_ request: URLRequest) throws -> URLRequest = { return $0 }) {
        self.authoriseStub = authoriseStub
    }

    @discardableResult
    func authorise(request: inout URLRequest) throws -> URLRequest {
        try authoriseStub(request)
    }
}
