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
        typealias ID = Int64
        let id: ID
        let type: SessionType
        let uuid: UUID
        let title: String
        let tag_list: String
        let start_time: Date
        let end_time: Date
        let deleted: Bool?
        let version: Int16
        let streams: [String : StreamOutput]
    }
    
    struct StreamOutput: Decodable, Hashable, Identifiable {
        let id: Int
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
        let id: Int
        let value: Float
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        let time: Date
        let stream_id: Int
        let milliseconds: Double
        let measured_value: Double
    }

    #warning("Static API calls?")
    static func getFixedMeasurement(uuid: UUID, lastSync: Date) -> AnyPublisher<FixedMeasurementOutput, Error> {
        FixedSessionService().getFixedMeasurement(uuid: uuid, lastSync: lastSync)
    }
}

final class FixedSessionService {
    let apiClient: APIClient
    let responseValidator: HTTPResponseValidator
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

    init(apiClient: APIClient = URLSession.shared, responseValidator: HTTPResponseValidator = DefaultHTTPResponseValidator()) {
        self.apiClient = apiClient
        self.responseValidator = responseValidator
    }

    func getFixedMeasurement(uuid: UUID, lastSync: Date) -> AnyPublisher<FixedSession.FixedMeasurementOutput, Error> {
        // Build URL with query
        var components = URLComponents(string: "http://aircasting.org/api/realtime/sync_measurements.json")!
        let syncDateStr = ISO8601DateFormatter.defaultLong.string(from: lastSync)
        components.queryItems = [
            URLQueryItem(name: "uuid", value: uuid.uuidString),
            URLQueryItem(name: "last_measurement_sync", value: syncDateStr)
        ]
        let url = components.url!

        // Build URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.signWithToken()

        return apiClient.fetchPublisher(for: request)
            .tryMap { [decoder, responseValidator] (data, response) -> FixedSession.FixedMeasurementOutput in
                try responseValidator.validate(response: response, data: data)
                return try decoder.decode(FixedSession.FixedMeasurementOutput.self, from: data)
            }.eraseToAnyPublisher()
    }
}

final class DefaultHTTPResponseValidator: HTTPResponseValidator {
    func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse, userInfo: ["data": data, "response": response])
        }
        switch httpResponse.statusCode {
        case 200..<300:
            return
            // TODO: throw proper error
        default:
            throw URLError(.badServerResponse, userInfo: ["data": data, "response": response])
        }

    }
}

protocol HTTPResponseValidator {
    func validate(response: URLResponse, data: Data) throws
}
