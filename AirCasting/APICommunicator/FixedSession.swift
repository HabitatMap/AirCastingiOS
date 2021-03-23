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
        var deleted: Bool
        var version: Int
        var streams: [StreamOutput]
    }
    
    struct StreamOutput: Codable {
        let sensor_name: String
        let sensor_package_name: String
        let unit_name: String
        let measurement_type: String
        let measurement_short_type: String
        let unit_symbol: String
        let threshold_very_low: Int
        let threshold_low: Int
        let threshold_medium: Int
        let threshold_high: Int
        let threshold_very_high: Int
        let deleted: Bool
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
    
    static func getFixedMeasurement() -> AnyPublisher<FixedMeasurementOutput, Error> {
        let url = URL(string: "http://aircasting.org/api/realtime/sync_measurements.json")!
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
        guard let authToken = UserDefaults.authToken else { return }
        let auth = "\(authToken):X".data(using: .utf8)!.base64EncodedString()
        setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
    }
    
}
