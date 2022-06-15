// Created by Lunar on 16/02/2022.
//

import Foundation
import Resolver

protocol SessionsForLocationDownloader {
    func getSessions(geoSquare: GeoSquare, timeFrom: Double, timeTo: Double, measurementType: MapDownloaderMeasurementType, sensor: MapDownloaderSensorType, completion: @escaping (Result<[MapDownloaderSearchedSession], Error>) -> Void)
}

class SessionsForLocationDownloaderDefault: SessionsForLocationDownloader {
    
    private struct FollowingSessions: Codable {
        let sessions: [MapDownloaderSearchedSession]
    }
    
    @Injected private var authorization: RequestAuthorisationService
    @Injected private var urlProvider: URLProvider
    @Injected private var client: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    
    func getSessions(geoSquare: GeoSquare, timeFrom: Double, timeTo: Double, measurementType: MapDownloaderMeasurementType, sensor: MapDownloaderSensorType, completion: @escaping (Result<[MapDownloaderSearchedSession], Error>) -> Void) {
        let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/fixed/active/sessions.json")
        
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        
        let query = MapDownloaderQuery(timeFrom: "\(Int(timeFrom))",
                                       timeTo: "\(Int(timeTo))",
                                       tags: "",
                                       usernames: "",
                                       west: geoSquare.west,
                                       east: geoSquare.east,
                                       south: geoSquare.south,
                                       north: geoSquare.north,
                                       limit: 100,
                                       offset: 0,
                                       sensorName: sensor.sensorNamePrefix + measurementType.sensorNameSuffix,
                                       measurementType: measurementType.apiName,
                                       unitSymbol: getProperUnitSymbol(using: measurementType).name)
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let encodedQuery = try encoder.encode(query)
            let jsonString = String(data: encodedQuery, encoding: .utf8)!
            urlComponents.queryItems = [
                URLQueryItem(name: "q", value: jsonString),
            ]
            
            let url = urlComponents.url!
            var request = URLRequest.jsonGET(url: url)
            
            try authorization.authorise(request: &request)
            client.requestTask(for: request) { [responseValidator] response, _ in
                switch response {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let response):
                    do {
                        try responseValidator.validate(response: response.response, data: response.data)
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let sessionData = try decoder.decode(FollowingSessions.self, from: response.data)
                        completion(.success(sessionData.sessions))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}

extension SessionsForLocationDownloaderDefault {
    func getProperUnitSymbol(using parameter: MapDownloaderMeasurementType) -> MapDownloaderUnitSymbol {
        switch parameter {
        case .particulateMatter:
            return .uqm3
        case .ozone:
            return .ppb
        }
    }
}
