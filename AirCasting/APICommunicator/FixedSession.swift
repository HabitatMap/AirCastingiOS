//
//  GetFixedMeasurements.swift
//  AirCasting
//
//  Created by Lunar on 22/03/2021.
//

import Foundation
import Combine

class FixedSession {
    
    struct MeasurementsOutput: Codable {
        
    }
    
    static func getFixedMeasurement(input: String) -> AnyPublisher<MeasurementsOutput, Error> {
        let url = URL(string: "http://aircasting.org/api/realtime/sync_measurements.json")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields?["Content-Type"] = "application/json"
        request.signWithToken()
        
        //let encoder = JSONEncoder()
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                let decoder = JSONDecoder()
                let fixedSessionOutput = try decoder.decode(MeasurementsOutput.self, from: data)
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
