//
//  GetFixedMeasurements.swift
//  AirCasting
//
//  Created by Lunar on 22/03/2021.
//

import Foundation
import Combine

class FixedSession {
    
    struct FixedMeasurementOutput: Codable {
        var type: String
        var uuid: String
        var title: String
        var tag_list: String
        var start_time: String
        var end_time: String
        var deleted: Bool?
        var version: Int
        var streams: [String : StreamOutput]
    }
    
    struct StreamOutput: Codable {
        let sensor_name: String
        let sensor_package_name: String
        let measurement_type: String
        let measurement_short_type: String
        let unit_name: String
        let unit_symbol: String
        let threshold_very_low: Int
        let threshold_low: Int
        let threshold_medium: Int
        let threshold_high: Int
        let threshold_very_high: Int
        let deleted: Bool?
        var measurements: [MeasurementOutput]
    }
    
    struct MeasurementOutput: Codable {
        let id: Int
        let values: Int
        let latitude: Int
        let longitude: Int
        let time: String
        let stream_id: Int
        let miliseconds: Int
        let measured_value: Int
    }
    
    static func getFixedMeasurement(uuid: UUID, lastSync: Date) -> AnyPublisher<FixedMeasurementOutput, Error> {
        
        // Build URL with query
        var components = URLComponents(string: "http://aircasting.org/api/realtime/sync_measurements.json")!
        let syncDateStr = ISO8601DateFormatter().string(from: lastSync)
        components.queryItems = [
            URLQueryItem(name: "uuid", value: uuid.uuidString),
            URLQueryItem(name: "last_measurement_sync", value: syncDateStr)
        ]
        let url = components.url!

        // Build URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields?["Content-Type"] = "application/json"
        request.signWithToken()
        
        //let encoder = JSONEncoder()
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                let decoder = JSONDecoder()
                let fixedSessionOutput = try decoder.decode(FixedMeasurementOutput.self, from: data)
                return fixedSessionOutput
                // TODO: parse and save to core data
            }
            .eraseToAnyPublisher()
    }
}

extension URLRequest {
    
    mutating func signWithToken() {
        // TODO:
//        guard let authToken = UserDefaults.authToken else { return }
//        let auth = "\(authToken):X".data(using: .utf8)!.base64EncodedString()
//        setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        setValue("Basic bXZGbS1HQ3dNR1NaUXd2cDgydXk=:X", forHTTPHeaderField: "Authorization")
    }
    
}
