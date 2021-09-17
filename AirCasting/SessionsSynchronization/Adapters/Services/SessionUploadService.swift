// Created by Lunar on 13/06/2021.
//

import Foundation
import Combine
import Gzip
import CoreLocation

final class SessionUploadService: SessionUpstream {
    private let client: APIClient
    private let authorization: RequestAuthorisationService
    private let responseValidator: HTTPResponseValidator
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        encoder.dateEncodingStrategy = .formatted(formatter)
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return encoder
    }()
    
    private struct APICallData: Encodable {
        let session: String
        let compression: Bool
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
                let sessionData = try encoder.encode(session)
                let gzippedSessionData = try sessionData.gzipped()
                let sessionBase64String = gzippedSessionData.base64EncodedString(options: [.lineLength76Characters, .endLineWithLineFeed])
                let apiCallData = APICallData(session: sessionBase64String, compression: true)
                let apiCallBody = try encoder.encode(apiCallData)
                request.httpBody = apiCallBody
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
