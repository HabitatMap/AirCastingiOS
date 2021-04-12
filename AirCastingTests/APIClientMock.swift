//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import Combine
@testable import AirCasting

final class APIClientMock: APIClient {
    var fetchPublisherStub: ((_ request: URLRequest) -> Result<(data: Data, response: URLResponse), URLError>)!

    func fetchPublisher(for request: URLRequest) -> APIClient.APIPublisher {
        fetchPublisherStub(request).publisher.eraseToAnyPublisher()
    }

    @discardableResult
    func returning(_ response: @autoclosure @escaping () -> (data: Data, response: HTTPURLResponse)) -> Self {
        fetchPublisherStub = { _ in .success(response()) }
        return self
    }

    @discardableResult
    func failing(with error: @autoclosure @escaping () -> URLError) -> Self {
        fetchPublisherStub = { _ in .failure(error()) }
        return self
    }
}

extension HTTPURLResponse {
    static func success(url: URL = URL(string: "http://test.com")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
}
