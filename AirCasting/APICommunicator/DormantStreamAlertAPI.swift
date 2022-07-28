// Created by Lunar on 28/07/2022.
//

import Foundation
import Resolver

enum DormantStreamAlertAPIError: Error {
    case failedRequest(Error)
}

struct DormantStreamAlertAPI {
    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var validator: HTTPResponseValidator
    
    func sendNewSetting(value: Bool, completion: @escaping (Result<Void, DormantStreamAlertAPIError>) -> Void) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/user/settings")
        
        let params = ["session_stopped_alert": value]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        _ = apiClient.requestTask(for: request) { [validator] result, request in
            do {
                switch result {
                case .failure(let error): completion(.failure(.failedRequest(error)))
                case .success((let data, let response)):
                    try validator.validate(response: response, data: data)
                    completion(.success(()))
                }
            } catch {
                completion(.failure(.failedRequest(error)))
            }
        }
        
    }
}
