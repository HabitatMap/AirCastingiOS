// Created by Lunar on 15/07/2021.
//

import Foundation

final class EmailResetPasswordService: ResetPasswordService {
    
    private let apiClient: APIClient
    private let validator: HTTPResponseValidator
    
    init(apiClient: APIClient, validator: HTTPResponseValidator) {
        self.apiClient = apiClient
        self.validator = validator
    }
    
    func resetPassword(login: String, completion: @escaping (Result<Void, ResetPasswordServiceError>) -> Void) {
        let params = ["user": ["login": login]]
        #warning("TODO: Let's use URLProvider")
        var request = URLRequest(url: URL(string: "http://aircasting.org/users/password.json")!)
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
