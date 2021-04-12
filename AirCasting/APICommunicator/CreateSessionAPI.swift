//
//  CreateSessionAPI.swift
//  AirCasting
//
//  Created by Lunar on 05/03/2021.
//

import Foundation
import Combine
import Gzip

class CreateSessionApi {
    
    let userDefaults = UserDefaults.standard
    
    struct MeasurementParams: Codable {
        var longitude: Double?
        var latitude: Double?
        var milliseconds: Int
        var time: Date
        var value: Double?
    }
    
    struct MeasurementStreamParams: Codable {
        var deleted: Bool
        var sensor_package_name: String
        var sensor_name: String?
        var measurement_type: String?
        var measurement_short_type: String?
        var unit_name: String?
        var unit_symbol: String?
        var threshold_very_high: Int?
        var threshold_high: Int?
        var threshold_medium: Int?
        var threshold_low: Int?
        var threshold_very_low: Int?
        var measurements: [MeasurementParams]
    }
    
    struct SessionParams: Codable {
        var uuid: String
        var type: String // SessionType.toString()
        var title: String
        var tag_list: String
        var start_time: Date
        var end_time: Date
        var contribute: Bool
        var is_indoor: Bool
        var notes: [String] // TODO: handle after adding notes
        var version: Int
        var streams: [String : MeasurementStreamParams]

        var latitude: Double?
        var longitude: Double?
    }
        
    struct Output: Codable {
        let location: String
    }
    
    struct Input: Codable {
        let session: SessionParams
        var compression: Bool = true
    }
    
    private struct APIInput: Codable {
        let session: String
        var compression: Bool = true
    }
    
    
    func createEmptyFixedWifiSession(input: Input) -> AnyPublisher<Output, Error> {
        let url = URL(string: "http://aircasting.org/api/realtime/sessions.json")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields?["Content-Type"] = "application/json"
        
        
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        encoder.dateEncodingStrategy = .formatted(formatter)
        
        let inputJSONData = try! encoder.encode(input.session)
        let gzippedData = try! inputJSONData.gzipped()
        let sessionBase64String = gzippedData.base64EncodedString()
        
        let apiInput = APIInput(session: sessionBase64String,
                                compression: input.compression)

        let apiPostData = try? encoder.encode(apiInput)
        request.httpBody = apiPostData
        request.signWithToken()
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                let decoder = JSONDecoder()
                let userOutput = try decoder.decode(Output.self, from: data)
                return userOutput
            }
            .eraseToAnyPublisher()
    }
}

#if DEBUG
extension CreateSessionApi.Input {
    
    static var mock: CreateSessionApi.Input {
        
        let session = CreateSessionApi.SessionParams(uuid: UUID().uuidString,
                                                     type: SessionType.FIXED.description,
                                                     title: "Test-1",
                                                     tag_list: "",
                                                     start_time: Date(),
                                                     end_time: Date().addingTimeInterval(3600),
                                                     contribute: true,
                                                     is_indoor: true,
                                                     notes: [],
                                                     version: 0,
                                                     streams: [:],
                                                     latitude: nil,
                                                     longitude: nil)
        
        let input = CreateSessionApi.Input(session: session, compression: true)
        return input
    }
}

#endif
