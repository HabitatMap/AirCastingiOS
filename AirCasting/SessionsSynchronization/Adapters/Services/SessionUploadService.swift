// Created by Lunar on 13/06/2021.
//

import Foundation
import Combine
import Gzip
import CoreLocation
import Resolver

final class SessionUploadService: SessionUpstream {
    @Injected private var client: APIClient
    @Injected private var authorization: RequestAuthorisationService
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var urlProvider: URLProvider
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let formatter = DateFormatters.SessionUploadService.encoderDateFormatter
        encoder.dateEncodingStrategy = .formatted(formatter)
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return encoder
    }()
    
    private let decoder = JSONDecoder()
    
    private struct APICallData: Encodable {
        let session: String
        let compression: Bool
    }
    
    func upload(session: SessionsSynchronization.SessionUpstreamData) -> Future<SessionsSynchronization.SessionUpstreamResult, Error> {
        .init { [self, client, authorization, encoder, responseValidator] promise in
            let url = urlProvider.baseAppURL.appendingPathComponent("api/sessions")
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
                    result.tryMap { result -> SessionsSynchronization.SessionUpstreamResult in
                        try responseValidator.validate(response: result.response, data: result.data)
                        let response = try self.decoder.decode(SessionsSynchronization.SessionUpstreamResult.self, from: result.data)
                        return response
                    }
                )
            }
        }
    }
}
