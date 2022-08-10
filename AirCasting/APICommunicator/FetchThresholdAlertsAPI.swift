// Created by Lunar on 10/08/2022.
//

import Foundation
import Resolver

protocol FetchThresholdAlertsAPI {
    func fetchAlerts(completion: @escaping (Result<[FetchedThresholdAlert], Error>) -> ())
}

struct FetchedThresholdAlert: Decodable {
    let id: Int
    let sessionUuid: String
    let sensorName: String
    let thresholdValue: Int
    let frequency: Int
}

class DefaultFetchThresholdAlertsAPI: FetchThresholdAlertsAPI {
    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var authorisationService: RequestAuthorisationService
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func fetchAlerts(completion: @escaping (Result<[FetchedThresholdAlert], Error>) -> ()) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/fixed/threshold_alerts")
        var request = URLRequest.jsonGET(url: url)
        
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
                    let data = try self.decoder.decode([FetchedThresholdAlert].self, from: response.data)
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
