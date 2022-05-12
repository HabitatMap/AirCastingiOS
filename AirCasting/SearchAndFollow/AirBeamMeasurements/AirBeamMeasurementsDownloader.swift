// Created by Lunar on 26/04/2022.
//
import SwiftUI
import Resolver

protocol AirBeamMeasurementsDownloader {
    func downloadStreams(with sessionID: Int, for airbeam: AirBeamStreamPrefix, completion: @escaping (Result<[MeasurementsDownloaderResultModel], Error>) -> Void) throws
}

final class AirBeamMeasurementsDownloaderDefault: AirBeamMeasurementsDownloader {
    @Injected private var urlProvider: URLProvider
    @Injected private var client: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    private let responseHandler = AuthorizationHTTPResponseHandler()
    
    func downloadStreams(with sessionID: Int, for airbeam: AirBeamStreamPrefix, completion: @escaping (Result<[MeasurementsDownloaderResultModel], Error>) -> Void) throws {
        let decoder = JSONDecoder()
        let group = DispatchGroup()
        var combinedResult = [MeasurementsDownloaderResultModel]()
        
        let requests = prepareRequests(using: sessionID, sensor: airbeam)
        
        var allErrors: [Error] = []
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
                        allErrors.append(error)
                        Log.info("Error when downloading one of the AirBeam streams: \(error)")
                        group.leave()
                    }
                case .failure(let error):
                    allErrors.append(error)
                    Log.info("Error when downloading one of the AirBeam streams: \(error)")
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            if !allErrors.isEmpty { completion(.failure(allErrors.first!)) }
            Log.info("Downloading all of the streams for AirBeam - completed.")
            completion(.success(combinedResult))
        }
    }
    
    private func prepareRequests(using sessionID: Int, sensor: AirBeamStreamPrefix) -> [URLRequest] {
        return AirBeamStreamSuffixes.allCases.map { suffix in
            let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/fixed/sessions/\(sessionID).json")
            let url = structureURLComponents(with: urlComponentPart, name: suffix, sensor: sensor)
            let request = URLRequest.jsonGET(url: url)
            return request
        }
    }
    
    private func structureURLComponents(with urlComponentPart: URL, name: AirBeamStreamSuffixes, sensor: AirBeamStreamPrefix) -> URL {
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "sensor_name", value: "\(sensor.rawName)-\(name.rawName)"),
            // optional parameter: measurements_limit (on the web is equal to 1440)
            URLQueryItem(name: "measurements_limit", value: "10"),
        ]
        return urlComponents.url!
    }
}