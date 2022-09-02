// Created by Lunar on 28/07/2022.
//

import Foundation
import Resolver

protocol DormantStreamAlertService {
    func sendNewSetting(value: Bool, completion: @escaping (Result<Void, DormantStreamAlertAPIError>) -> Void)
}

enum DormantStreamAlertAPIError: Error {
    case wrongRequest
    case failedRequest(Error)
}

struct DefaultDormantStreamAlertAPI: DormantStreamAlertService {
    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var validator: HTTPResponseValidator
    @Injected private var authorization: RequestAuthorisationService
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    struct Params: Encodable {
        private let data: Nested
        
        struct Nested: Encodable {
            let sessionStoppedAlert: String
        }
        
        init(value: Bool) {
            self.data = Nested(sessionStoppedAlert: String(value))
        }
    }
    
    struct Output: Decodable {
        let action: String
    }
    
    func sendNewSetting(value: Bool, completion: @escaping (Result<Void, DormantStreamAlertAPIError>) -> Void) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/user/settings")
        
        let params = Params(value: value)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        do {
            request.httpBody = try encoder.encode(params)
            try authorization.authorise(request: &request)
        } catch {
            Log.error("Failed to prepare request")
            completion(.failure(.wrongRequest))
        }
        
        apiClient.requestTask(for: request) { [validator] result, request in
            do {
                switch result {
                case .failure(let error): completion(.failure(.failedRequest(error)))
                case .success((let data, let response)):
                    try validator.validate(response: response, data: data)
                    let responseMessage = try decoder.decode(Output.self, from: data)
                    Log.info("Server response: \(responseMessage.action)")
                    completion(.success(()))
                }
            } catch {
                completion(.failure(.failedRequest(error)))
            }
        }
        
    }
}
