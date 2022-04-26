// Created by Lunar on 26/04/2022.
//
import SwiftUI
import Resolver

final class AirBeamMeasurementsDownloader {
    @Injected private var urlProvider: URLProvider
    @Injected private var client: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    private let responseHandler = AuthorizationHTTPResponseHandler()
    
    func downloadStreams(using sessionID: Int, completion: @escaping (Result<[MeasurementsDownloaderResultModel], Error>) -> Void) throws {
        let decoder = JSONDecoder()
        let group = DispatchGroup()
        var requests = [URLRequest]()
        var combinedResult = [MeasurementsDownloaderResultModel]()
        
        AirBeamStreamSuffixes.allCases.forEach { s in
            let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/fixed/sessions/\(sessionID).json")
            var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
            urlComponents.queryItems = [
                URLQueryItem(name: "sensor_name", value: "airbeam3-\(s.rawName)"),
                // optional parameter: measurements_limit (on the web is equal to 1440)
                URLQueryItem(name: "measurements_limit", value: "10"),
            ]
            let url = urlComponents.url!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            requests.append(request)
        }
        
        for request in requests {
            group.enter()
            client.requestTask(for: request) { [responseValidator] result, _ in
                switch result {
                case .success(let response):
                    do {
                        try responseValidator.validate(response: response.response, data: response.data)
                        let resultPart = try decoder.decode(MeasurementsDownloaderResultModel.self, from: response.data)
                        combinedResult.append(resultPart)
                        group.leave()
                    } catch {
                        completion(.failure(error))
                        fatalError("Error when downloading one of the AirBeam streams: \(error)")
                    }
                case .failure(let error):
                    completion(.failure(error))
                    fatalError("Error when downloading one of the AirBeam streams: \(error)")
                }
            }
        }
        group.notify(queue: .main) {
            Log.info("Downloading all of the streams for AirBeam - completed.")
            completion(.success(combinedResult))
        }
    }
}
