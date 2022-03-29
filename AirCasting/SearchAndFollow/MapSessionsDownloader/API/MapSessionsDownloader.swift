// Created by Lunar on 16/02/2022.
//

import Foundation
import Resolver
import SwiftUI

protocol MapSessionsDownloader {
    func getSessions(geoSquare: GeoSquare,  completion: @escaping (Result<[SearchedSession], Error>) -> Void)
}

// swiftlint:disable print_using
class MapSessionsDownloaderDefault: MapSessionsDownloader {
    @Injected private var authorization: RequestAuthorisationService
    @Injected private var urlProvider: URLProvider
    @Injected private var client: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    
    func getSessions(geoSquare: GeoSquare,  completion: @escaping (Result<[SearchedSession], Error>) -> Void) {
        let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("/api/fixed/active/sessions.json")
        
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        
        // We are going to use current day and current day year ago
        let timeFrom = DateBuilder.beginingOfDayInSeconds(using: DateBuilder.yearAgo())
        let timeTo = DateBuilder.endOfDayInSeconds(using: DateBuilder.getRawDate())
        
        let query = Query(timeFrom: "\(Int(timeFrom))",
                          timeTo: "\(Int(timeTo))",
                          tags: "",
                          usernames: "",
                          west: geoSquare.west,
                          east: geoSquare.east,
                          south: geoSquare.south,
                          north: geoSquare.north,
                          limit: 100,
                          offset: 0,
                          sensor_name: "openaq-pm2.5",
                          measurement_type: MeasurementType.particulateMatter.name,
                          unitSymbol: UnitSymbol.uqm3.name)
        do {
            let encodedQuery = try JSONEncoder().encode(query)
            let jsonString = String(data: encodedQuery, encoding: .utf8)!
            urlComponents.queryItems = [
                URLQueryItem(name: "q", value: jsonString),
            ]
            
            let url = urlComponents.url!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            try authorization.authorise(request: &request)
            client.requestTask(for: request) { [responseValidator] response, _ in
                switch response {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let response):
                    do {
                        try responseValidator.validate(response: response.response, data: response.data)
                        let decoder = JSONDecoder()
                        let sessionData = try decoder.decode(SearchedSessions.self, from: response.data)
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

// swiftlint:enable print_using
