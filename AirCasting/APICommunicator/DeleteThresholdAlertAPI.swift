// Created by Lunar on 08/08/2022.
//

import Foundation
import Resolver

protocol DeleteThresholdAlertAPI {
    func DeleteAlert(id: Int, completion: @escaping (Result<Void, Error>) -> ())
}

class DefaultDeleteThresholdAlertAPI: DeleteThresholdAlertAPI {
    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var authorisationService: RequestAuthorisationService
    
    func DeleteAlert(id: Int, completion: @escaping (Result<Void, Error>) -> ()) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/fixed/threshold_alerts/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            try authorisationService.authorise(request: &request)
        } catch {
            completion(.failure(error))
        }

        apiClient.requestTask(for: request) { [responseValidator] result, request in
            switch result {
            case .success(let response):
                do {
                    try responseValidator.validate(response: response.response, data: response.data)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
