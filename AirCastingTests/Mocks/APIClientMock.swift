//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import Combine
@testable import AirCasting

final class APIClientMock: APIClient {
    var callHistory: [URLRequest] = []
    
    var requestTaskStub: ((_ request: URLRequest, _ completion: @escaping (Result<(data: Data, response: HTTPURLResponse), Error>, URLRequest) -> Void) -> Void)!

    func requestTask(for request: URLRequest, completion: @escaping (Result<(data: Data, response: HTTPURLResponse), Error>, URLRequest) -> Void) -> Cancellable {
        callHistory.append(request)
        requestTaskStub(request, completion)
        return EmptyCancellable()
    }

    @discardableResult
    func returning(_ response: @autoclosure @escaping () -> (data: Data, response: HTTPURLResponse)) -> Self {
        requestTaskStub = { request, completion in
            completion(.success(response()), request)
        }
        return self
    }

    @discardableResult
    func failing(with error: @autoclosure @escaping () -> URLError) -> Self {
        requestTaskStub = { request, completion in
            completion(.failure(error()), request)
        }
        return self
    }
}

extension HTTPURLResponse {
    static func success(url: URL = URL(string: "http://test.com")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
}
