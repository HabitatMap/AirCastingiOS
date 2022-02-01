//
//  GetFixedMeasurements.swift
//  AirCasting
//
//  Created by Lunar on 22/03/2021.
//

import Foundation
import Combine
import CoreLocation

class FixedSession {
    struct FixedMeasurementOutput: Decodable, Hashable {
        let type: SessionType
        let uuid: SessionUUID
        let title: String
        let tag_list: String
        let start_time: Date
        let end_time: Date
        let deleted: Bool?
        let version: Int16
        let streams: [String : StreamOutput]
    }
    
    struct StreamOutput: Decodable, Hashable, Identifiable {
        typealias ID = Int64
        let id: ID
        let sensor_name: String
        let sensor_package_name: String
        let measurement_type: String
        let measurement_short_type: String
        let unit_name: String
        let unit_symbol: String
        let threshold_very_low: Int32
        let threshold_low: Int32
        let threshold_medium: Int32
        let threshold_high: Int32
        let threshold_very_high: Int32
        let deleted: Bool?
        let measurements: [MeasurementOutput]
    }
    
    struct MeasurementOutput: Decodable, Hashable, Identifiable {
        typealias ID = Int64
        let id: ID
        let value: Float
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        let time: Date
        let stream_id: Int
        let milliseconds: Double
        //TODO: Fix this. We need to make it optional, because when we get measurements for sessions from SD Card, their measuredValue is nil
        let measured_value: Double?
    }
}

final class FixedSessionAPIService {
    let urlProvider: BaseURLProvider
    let apiClient: APIClient
    let responseValidator: HTTPResponseValidator
    let authorisationService: RequestAuthorisationService
    private lazy var decoder: JSONDecoder = {
        $0.dateDecodingStrategy = .custom({
            let container = try $0.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = ISO8601DateFormatter.defaultLong.date(from: value) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected date string to be ISO8601-formatted.")
            }
            return date
        })
        return $0
    }(JSONDecoder())

    init(authorisationService: RequestAuthorisationService, apiClient: APIClient = URLSession.shared, responseValidator: HTTPResponseValidator = DefaultHTTPResponseValidator(), baseUrl: BaseURLProvider) {
        self.authorisationService = authorisationService
        self.apiClient = apiClient
        self.responseValidator = responseValidator
        self.urlProvider = baseUrl
    }

    @discardableResult
    func getFixedMeasurement(uuid: SessionUUID, lastSync: Date, completion: @escaping (Result<FixedSession.FixedMeasurementOutput, Error>) -> Void) -> Cancellable {
        // Build URL with query
        let url = urlProvider.baseAppURL.appendingPathComponent("api/realtime/sync_measurements.json")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let syncDateStr = ISO8601DateFormatter.defaultLong.string(from: lastSync)
        components.queryItems = [
            URLQueryItem(name: "uuid", value: uuid.rawValue),
            URLQueryItem(name: "last_measurement_sync", value: syncDateStr)
        ]
        let urlWithParams = components.url!

        // Build URLRequest
        var request = URLRequest(url: urlWithParams)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            try authorisationService.authorise(request: &request)
            return apiClient.requestTask(for: request) { [responseValidator, decoder] result, _ in
                completion(result.tryMap({
                    try responseValidator.validate(response: $0.response, data: $0.data)
                    return try decoder.decode(FixedSession.FixedMeasurementOutput.self, from: $0.data)
                }))
            }
        } catch {
            completion(.failure(error))
            return EmptyCancellable()
        }
    }
}

