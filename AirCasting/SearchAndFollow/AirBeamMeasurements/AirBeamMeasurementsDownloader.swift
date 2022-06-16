// Created by Lunar on 26/04/2022.
//
import SwiftUI
import Resolver

protocol AirBeamMeasurementsDownloader {
    func downloadStreams(with sessionID: Int, completion: @escaping (Result<MeasurementsDownloaderResultModel, Error>) -> Void) throws
}

final class AirBeamMeasurementsDownloaderDefault: AirBeamMeasurementsDownloader {
    @Injected private var urlProvider: URLProvider
    @Injected private var client: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    private let responseHandler = AuthorizationHTTPResponseHandler()
    
    func downloadStreams(with sessionID: Int, completion: @escaping (Result<MeasurementsDownloaderResultModel, Error>) -> Void) throws {
        let decoder = JSONDecoder()
        let request = prepareRequests(using: sessionID)
        
        client.requestTask(for: request) { [responseValidator] result, _ in
            switch result {
            case .success(let response):
                do {
                    try responseValidator.validate(response: response.response, data: response.data)
                    let resultPart = try decoder.decode(MeasurementsDownloaderResultModel.self, from: response.data)
                    completion(.success(resultPart))
                } catch {
                    Log.info("Error when downloading one of the AirBeam streams: \(error)")
                }
            case .failure(let error):
                Log.info("Error when downloading one of the AirBeam streams: \(error)")
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
            // optional parameter: measurements_limit (on the web is equal to 1440)
            URLQueryItem(name: "measurements_limit", value: "1"),
        ]
        return urlComponents.url!
    }
}
