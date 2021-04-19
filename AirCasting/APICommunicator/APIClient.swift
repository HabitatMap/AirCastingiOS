//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import Combine

protocol APIClient {
    typealias APIPublisher = AnyPublisher<(data: Data, response: URLResponse), URLError>

    func fetchPublisher(for request: URLRequest) -> APIPublisher
}

extension APIClient {
    func fetchPublisher(with request: @autoclosure () throws -> URLRequest) -> APIPublisher {
        do {
            return fetchPublisher(for: try request())
        } catch {
            let publisher = PassthroughSubject<(data: Data, response: URLResponse), URLError>()
            publisher.send(completion: .failure(URLError(.userAuthenticationRequired, userInfo: [NSUnderlyingErrorKey: error])))
            return publisher.eraseToAnyPublisher()
        }
    }
}

extension URLSession: APIClient {
    func fetchPublisher(for request: URLRequest) -> APIPublisher {
        dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}

protocol RequestAuthorisationService {
    @discardableResult
    func authorise(request: inout URLRequest) throws -> URLRequest
}
