// Created by Lunar on 10/06/2021.
//

import Foundation
import Combine
import Resolver

final class SessionDownloadService: SessionDownstream, MeasurementsDownloadable {
    @Injected private var client: APIClient
    @Injected private var authorization: RequestAuthorisationService
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var urlProvider: URLProvider
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let formatter = DateFormatters.SessionDownloadService.decoderDateFormatter
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    func download(session: SessionUUID) -> AnyPublisher<SessionsSynchronization.SessionDownstreamData, Error> {
        // Warning: for this pattern to work the work cone by the `APIClient` must not be synchronous.
        // Otherwise we'd have to implement ReplySubject as Combine doesn't provide us with one. I think
        // we can safely assume that APIClient won't be synchronous.
        let subject = PassthroughSubject<SessionsSynchronization.SessionDownstreamData, Error>()
        let requestCancellable = download(session: session) { result in
            switch result {
            case .success(let data): subject.send(data); subject.send(completion: .finished)
            case .failure(let error): subject.send(completion: .failure(error))
            }
        }
        
        return subject
            .handleEvents(receiveCancel: {
                requestCancellable.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    private func download(session: SessionUUID, completion: @escaping (Result<SessionsSynchronization.SessionDownstreamData, Error>) -> Void) -> Cancellable {
        let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/user/sessions/empty.json")
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "uuid", value: session.rawValue)
        ]
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            try authorization.authorise(request: &request)
        } catch {
            completion(.failure(error))
            return EmptyCancellable()
        }
        
        return client.requestTask(for: request) { [responseValidator, decoder] result, request in
            switch result {
            case .success(let response):
                do {
                    try responseValidator.validate(response: response.response, data: response.data)
                    let sessionData = try decoder.decode(SessionsSynchronization.SessionDownstreamData.self, from: response.data)
                    completion(.success(sessionData))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func downloadSessionWithMeasurement(uuid: SessionUUID, completion: @escaping (Result<SessionsSynchronization.SessionDownstreamData, Error>) -> Void) -> Cancellable {
        let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/user/sessions/empty.json")
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "uuid", value: uuid.rawValue),
            URLQueryItem(name: "stream_measurements", value: "true")
        ]
        
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            try authorization.authorise(request: &request)
        } catch {
            completion(.failure(error))
            return EmptyCancellable()
        }
        
        return client.requestTask(for: request) { [responseValidator, decoder] result, request in
            switch result {
            case .success(let response):
                do {
                    try responseValidator.validate(response: response.response, data: response.data)
                    let sessionData = try decoder.decode(SessionsSynchronization.SessionDownstreamData.self, from: response.data)
                    completion(.success(sessionData))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
