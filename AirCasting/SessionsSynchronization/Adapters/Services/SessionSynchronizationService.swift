// Created by Lunar on 10/06/2021.
//

import Foundation
import Combine
import CoreLocation

final class SessionSynchronizationService: SessionSynchronizationContextProvidable {
    private let client: APIClient
    private let authorization: RequestAuthorisationService
    private let responseValidator: HTTPResponseValidator
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private struct APICallData: Encodable {
        let data: String
    }
    
    init(client: APIClient, authorization: RequestAuthorisationService, responseValidator: HTTPResponseValidator) {
        self.client = client
        self.authorization = authorization
        self.responseValidator = responseValidator
    }
    
    public func getSynchronizationContext(localSessions: [SessionsSynchronization.Metadata]) -> AnyPublisher<SessionsSynchronization.SynchronizationContext, Error> {
        // Warning: for this pattern to work the work cone by the `APIClient` must not be synchronous.
        // Otherwise we'd have to implement ReplySubject as Combine doesn't provide us with one. I think
        // we can safely assume that APIClient won't be synchronous.
        let subject = PassthroughSubject<SessionsSynchronization.SynchronizationContext, Error>()
        let url = URL(string: "http://aircasting.org/api/user/sessions/sync_with_versioning.json")!
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
                throw BodyEncodingError.dataCannotBeStringified
            }
            request.httpBody = try encoder.encode(APICallData(data: bodyString))
            try authorization.authorise(request: &request)
        } catch {
            subject.send(completion: .failure(error))
        }
        
        let requestCancellable = client.requestTask(for: request) { [responseValidator, decoder] result, request in
            let validatedResult = result.tryMap { data, response -> SessionsSynchronization.SynchronizationContext in
                try responseValidator.validate(response: response, data: data)
                return try decoder.decode(SessionsSynchronization.SynchronizationContext.self, from: data)
            }
            switch validatedResult {
            case .success(let context):
                subject.send(context)
                subject.send(completion: .finished)
            case .failure(let error):
                subject.send(completion: .failure(error))
            }
        }
        
        return subject
            .handleEvents(receiveSubscription: { _ in }, receiveCancel: { requestCancellable.cancel() })
            .eraseToAnyPublisher()
    }
}
