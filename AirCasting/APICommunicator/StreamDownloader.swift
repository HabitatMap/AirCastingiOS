// Created by Lunar on 29/03/2022.
//

import Foundation
import Resolver

protocol StreamDownloader {
    func downloadStreamWithMeasurements(id: String, completion: @escaping (Result<StreamWithMeasurementsDownstream, Error>) -> Void)
}

class DefaultStreamDownloader: StreamDownloader {
    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var authorisationService: RequestAuthorisationService
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func downloadStreamWithMeasurements(id: String, completion: @escaping (Result<StreamWithMeasurementsDownstream, Error>) -> Void) {
        let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/fixed/streams/\(id).json")
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        urlComponents.queryItems = [
//            URLQueryItem(name: "uuid", value: "nill"),
            URLQueryItem(name: "measurements_limit", value: "1140")
        ]
        
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            try authorisationService.authorise(request: &request)
        } catch {
            completion(.failure(error))
        }
        
        apiClient.requestTask(for: request) { [responseValidator, decoder] result, request in
            switch result {
            case .success(let response):
                do {
                    try responseValidator.validate(response: response.response, data: response.data)
                    let sessionData = try decoder.decode(StreamWithMeasurementsDownstream.self, from: response.data)
                    completion(.success(sessionData))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
