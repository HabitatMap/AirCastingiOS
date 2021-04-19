//
//  CreateSessionAPI.swift
//  AirCasting
//
//  Created by Lunar on 05/03/2021.
//

import Foundation
import Combine
import Gzip
import CoreLocation

class CreateSessionApi {
    struct MeasurementParams: Encodable {
        var longitude: CLLocationDegrees?
        var latitude: CLLocationDegrees?
        var milliseconds: Int
        var time: Date
        var value: Double?
    }
    
    struct MeasurementStreamParams: Encodable {
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
    
    struct SessionParams: Encodable {
        var uuid: SessionUUID
        var type: SessionType
        var title: String
        var tag_list: String
        var start_time: Date
        var end_time: Date
        var contribute: Bool
        var is_indoor: Bool
        #warning("TODO: handle after adding notes")
        var notes: [String]
        var version: Int
        var streams: [String : MeasurementStreamParams]

        var latitude: CLLocationDegrees?
        var longitude: CLLocationDegrees?
    }
        
    struct Output: Decodable, Hashable {
        let location: String
    }
    
    struct Input: Encodable {
        let session: SessionParams
        var compression: Bool = true
    }
}

final class CreateSessionAPIService {
    private struct APIInput: Codable {
        let session: String
        let compression: Bool
    }

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

    private lazy var encoder: JSONEncoder = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        $0.dateEncodingStrategy = .formatted(formatter)
        return $0
    }(JSONEncoder())

    init(authorisationService: RequestAuthorisationService, apiClient: APIClient = URLSession.shared, responseValidator: HTTPResponseValidator = DefaultHTTPResponseValidator()) {
        self.authorisationService = authorisationService
        self.apiClient = apiClient
        self.responseValidator = responseValidator
    }

    func createEmptyFixedWifiSession(input: CreateSessionApi.Input) -> AnyPublisher<CreateSessionApi.Output, Error> {
        let url = URL(string: "http://aircasting.org/api/realtime/sessions.json")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let inputJSONData = try! encoder.encode(input.session)
        let gzippedData = try! inputJSONData.gzipped()
        let sessionBase64String = gzippedData.base64EncodedString()

        let apiInput = APIInput(session: sessionBase64String,
                                compression: input.compression)

        let apiPostData = try! encoder.encode(apiInput)
        request.httpBody = apiPostData

        return apiClient.fetchPublisher(with: try authorisationService.authorise(request: &request))
            .tryMap { [decoder, responseValidator] (data, response) -> CreateSessionApi.Output in
                try responseValidator.validate(response: response, data: data)
                return try decoder.decode(CreateSessionApi.Output.self, from: data)
            }.eraseToAnyPublisher()
    }
}
