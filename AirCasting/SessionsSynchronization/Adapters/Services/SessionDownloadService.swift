// Created by Lunar on 10/06/2021.
//

import Foundation
import Combine

final class SessionDownloadService: SessionDownstream {
    private let client: APIClient
    private let authorization: RequestAuthorisationService
    private let responseValidator: HTTPResponseValidator
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    init(client: APIClient, authorization: RequestAuthorisationService, responseValidator: HTTPResponseValidator) {
        self.client = client
        self.authorization = authorization
        self.responseValidator = responseValidator
    }
    
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
        var urlComponents = URLComponents(string: "http://aircasting.org/api/user/sessions/empty.json")!
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
        var urlComponents = URLComponents(string: "http://aircasting.org/api/user/sessions/empty.json")!
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
                                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    completion(.success(sessionData))
                                         }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
