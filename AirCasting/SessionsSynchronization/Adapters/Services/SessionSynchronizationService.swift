// Created by Lunar on 10/06/2021.
//

import Foundation
import Combine
import CoreLocation
import Resolver

final class SessionSynchronizationService: SessionSynchronizationContextProvidable {
    @Injected private var client: APIClient
    @Injected private var authorization: RequestAuthorisationService
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var urlProvider: URLProvider
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private struct APICallData: Encodable {
        let data: String
    }
    
    public func getSynchronizationContext(localSessions: [SessionsSynchronization.Metadata]) -> AnyPublisher<SessionsSynchronization.SynchronizationContext, Error> {
        // Warning: for this pattern to work the work cone by the `APIClient` must not be synchronous.
        // Otherwise we'd have to implement ReplySubject as Combine doesn't provide us with one. I think
        // we can safely assume that APIClient won't be synchronous.
        let subject = PassthroughSubject<SessionsSynchronization.SynchronizationContext, Error>()
        let requestCancellable = getSynchronizationContext(localSessions: localSessions) { result in
            switch result {
            case .success(let data): subject.send(data); subject.send(completion: .finished)
            case .failure(let error): subject.send(completion: .failure(error))
            }
        }
        
        return subject
            .handleEvents(receiveSubscription: { _ in }, receiveCancel: { requestCancellable.cancel() })
            .eraseToAnyPublisher()
    }
    
    private func getSynchronizationContext(localSessions: [SessionsSynchronization.Metadata],
                                           completion: @escaping (Result<SessionsSynchronization.SynchronizationContext, Error>) -> Void) -> Cancellable {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/user/sessions/sync_with_versioning.json")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            // Server expects us to send JSON formatted as:
            // {
            //   "data": String
            // }
            // where `data` field is a *string* containing a JSON.
            //
            // 🤷‍♂️
            let bodyData = try encoder.encode(localSessions)
            guard let bodyString = String(data: bodyData, encoding: .utf8) else {
                throw BodyEncodingError.dataCannotBeStringified(data: bodyData)
            }
            request.httpBody = try encoder.encode(APICallData(data: bodyString))
            try authorization.authorise(request: &request)
        } catch {
            completion(.failure(error))
            return EmptyCancellable()
        }
        
        return client.requestTask(for: request) { [responseValidator, decoder] result, request in
            let validatedResult = result.tryMap { data, response -> SessionsSynchronization.SynchronizationContext in
                try responseValidator.validate(response: response, data: data)
                return try decoder.decode(SessionsSynchronization.SynchronizationContext.self, from: data)
            }
            switch validatedResult {
            case .success(let context):
                completion(.success(context))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
