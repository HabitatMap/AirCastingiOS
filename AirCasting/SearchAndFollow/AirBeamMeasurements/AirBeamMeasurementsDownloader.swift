// Created by Lunar on 26/04/2022.
//
import SwiftUI
import Resolver

protocol AirBeamMeasurementsDownloader {
    func downloadStreams(with sessionID: Int, completion: @escaping (Result<MeasurementsDownloaderResultModel, Error>) -> Void)
}

final class AirBeamMeasurementsDownloaderDefault: AirBeamMeasurementsDownloader {
    @Injected private var urlProvider: URLProvider
    @Injected private var client: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    private let responseHandler = AuthorizationHTTPResponseHandler()
    
    func downloadStreams(with sessionID: Int, completion: @escaping (Result<MeasurementsDownloaderResultModel, Error>) -> Void) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let request = prepareRequests(using: sessionID)
        
        client.requestTask(for: request) { [responseValidator] result, _ in
            switch result {
            case .success(let response):
                do {
                    try responseValidator.validate(response: response.response, data: response.data)
                    let resultPart = try decoder.decode(MeasurementsDownloaderResultModel.self, from: response.data)
                    completion(.success(resultPart))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func prepareRequests(using sessionID: Int) -> URLRequest {
        let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/fixed/sessions/\(sessionID)/streams.json")
        let url = structureURLComponents(with: urlComponentPart)
        let request = URLRequest.jsonGET(url: url)
        return request
    }
    
    private func structureURLComponents(with urlComponentPart: URL) -> URL {
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        urlComponents.queryItems = [
            // 1440 measurements so measurement every minute in 24h period
            URLQueryItem(name: "measurements_limit", value: "1440"),
        ]
        return urlComponents.url!
    }
}
