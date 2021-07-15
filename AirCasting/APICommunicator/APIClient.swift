//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import Combine

typealias Cancellable = Combine.Cancellable

struct EmptyCancellable: Cancellable {
    func cancel() { }
}

protocol APIClient {
    @discardableResult
    func requestTask(for request: URLRequest, completion: @escaping (Result<(data: Data, response: HTTPURLResponse), Error>, URLRequest) -> Void) -> Cancellable
}

extension URLSession: APIClient {
    func requestTask(for request: URLRequest, completion: @escaping (Result<(data: Data, response: HTTPURLResponse), Error>, URLRequest) -> Void) -> Cancellable {
        let task = dataTask(with: request) { data, response, error in
            guard let urlResponse = response as? HTTPURLResponse,
                  let rawData = data else {
                completion(.failure(error ?? URLError(.unknown, userInfo: ["data": data as Any, "response": response as Any, "request": request])), request)
                return
            }
            if let error = error {
                completion(.failure(error), request)
                return
            }
            completion(.success((data: rawData, response: urlResponse)), request)
        }
        task.resume()
        return URLSessionDataTaskCancellable(dataTask: task)
    }

    private struct URLSessionDataTaskCancellable: Cancellable {
        weak var dataTask: URLSessionDataTask?

        func cancel() {
            dataTask?.cancel()
        }
    }
}

protocol RequestAuthorisationService {
    @discardableResult
    func authorise(request: inout URLRequest) throws -> URLRequest
}

final class DefaultHTTPResponseValidator: HTTPResponseValidator {
    func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse, userInfo: ["data": data, "response": response])
        }
        switch httpResponse.statusCode {
        case 200..<300:
            return
        // TODO: throw proper error
        default:
            throw URLError(.badServerResponse, userInfo: ["data": data, "response": response])
        }
    }
}

protocol HTTPResponseValidator {
    func validate(response: URLResponse, data: Data) throws
}

extension Result {
    func tryMap<D>(_ block: (Success) throws -> D) -> Result<D, Error> {
        switch self {
        case .success(let response):
            return Result<D, Error>(catching: { try block(response) })
        case .failure(let error):
            return .failure(error)
        }
    }
}
