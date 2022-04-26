// Created by Lunar on 15/07/2021.
//

import Foundation
import Resolver

final class EmailResetPasswordService: ResetPasswordService {
    
    @Injected private var apiClient: APIClient
    @Injected private var validator: HTTPResponseValidator
    @Injected private var urlProvider: URLProvider
    
    func resetPassword(login: String, completion: @escaping (Result<Void, ResetPasswordServiceError>) -> Void) {
        let params = ["user": ["login": login]]
        let url = urlProvider.baseAppURL.appendingPathComponent("users/password.json")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        _ = apiClient.requestTask(for: request) { [validator] result, request in
            do {
                switch result {
                case .failure(let error): completion(.failure(.ioFailure(underlyingError: error)))
                case .success((let data, let response)):
                    try validator.validate(response: response, data: data)
                    completion(.success(()))
                }
            } catch {
                completion(.failure(.ioFailure(underlyingError: error)))
            }
        }
    }
}
