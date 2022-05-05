// Created by Lunar on 29/03/2022.
//

import Foundation
import Resolver

struct StreamWithMeasurements: Decodable {
    let title: String
    let username: String
    let measurements: [StreamWithMeasurements.Measurements]
    let id: Int
    let lastMeasurementValue: Double
    let sensorName: String
    let sensorUnit: String
    
    struct Measurements: Decodable {
        let value: Double
        let time: Int
        let longitude: Double
        let latitude: Double
    }
}

protocol StreamDownloader {
    func downloadStreamWithMeasurements(id: String, measurementsLimit: Int, completion: @escaping (Result<StreamWithMeasurements, Error>) -> Void)
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
    
    func downloadStreamWithMeasurements(id: String, measurementsLimit: Int, completion: @escaping (Result<StreamWithMeasurements, Error>) -> Void) {
        let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/fixed/streams/\(id).json")
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "measurements_limit", value: String(measurementsLimit))
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
                    let sessionData = try decoder.decode(StreamWithMeasurements.self, from: response.data)
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
