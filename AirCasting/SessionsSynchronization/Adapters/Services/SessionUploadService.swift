// Created by Lunar on 13/06/2021.
//

import Foundation
import Combine
import CoreLocation

final class AirCastingSessionUploadService: SessionUpstream {
    private let client: APIClient
    private let authorization: RequestAuthorisationService
    private let responseValidator: HTTPResponseValidator
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        encoder.dateEncodingStrategy = .formatted(formatter)
        return encoder
    }()
    
    private struct APICallData: Encodable {
        let session: String
    }
    
    init(client: APIClient, authorization: RequestAuthorisationService, responseValidator: HTTPResponseValidator) {
        self.client = client
        self.authorization = authorization
        self.responseValidator = responseValidator
    }
    
    func upload(session: SessionsSynchronization.SessionUpstreamData) -> Future<Void, Error> {
        .init { [client, authorization, encoder, responseValidator] promise in
            let url = URL(string: "http://aircasting.org/api/sessions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                // Server expects us to send JSON formatted as:
                // {
                //   "session": String
                // }
                // where `session` field is a *string* containing a JSON.
                //
                // 🤷‍♂️
                let bodyData = try encoder.encode(session)
                guard let bodyString = String(data: bodyData, encoding: .utf8) else {
                    throw BodyEncodingError.dataCannotBeStringified
                }
                request.httpBody = try encoder.encode(APICallData(session: bodyString))
                try authorization.authorise(request: &request)
            } catch {
                promise(.failure(error))
            }
            client.requestTask(for: request) { result, request in
                promise(
                    result.tryMap { result -> Void in
                        try responseValidator.validate(response: result.response, data: result.data)
                        return ()
                    }
                )
            }
        }
    }
}
