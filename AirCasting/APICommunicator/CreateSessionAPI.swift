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
        let longitude: CLLocationDegrees?
        let latitude: CLLocationDegrees?
        let milliseconds: Int
        let time: Date
        let value: Double?
    }
    
    struct MeasurementStreamParams: Encodable {
        let deleted: Bool
        let sensor_package_name: String
        let sensor_name: String?
        let measurement_type: String?
        let measurement_short_type: String?
        let unit_name: String?
        let unit_symbol: String?
        let threshold_very_high: Int?
        let threshold_high: Int?
        let threshold_medium: Int?
        let threshold_low: Int?
        let threshold_very_low: Int?
        let measurements: [MeasurementParams]
    }
    
    struct SessionParams: Encodable {
        let uuid: SessionUUID
        let type: SessionType
        let title: String
        let tag_list: String
        let start_time: Date
        let end_time: Date
        let contribute: Bool
        let is_indoor: Bool
        let notes: [String]
        let version: Int
        let streams: [String : MeasurementStreamParams]

        let latitude: CLLocationDegrees?
        let longitude: CLLocationDegrees?
    }
        
    struct Output: Decodable, Hashable {
        let location: String
    }
    
    struct Input: Encodable {
        let session: SessionParams
        let compression: Bool
    }
}

final class CreateSessionAPIService {
    private struct APIInput: Codable {
        let session: String
        let compression: Bool
    }
    
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

    private lazy var encoder: JSONEncoder = {
        let formatter = DateFormatters.CreateSessionAPIService.encoderDateFormatter
        $0.dateEncodingStrategy = .formatted(formatter)
        return $0
    }(JSONEncoder())

    init(authorisationService: RequestAuthorisationService, apiClient: APIClient = URLSession.shared, responseValidator: HTTPResponseValidator = DefaultHTTPResponseValidator(), baseUrlProvider: BaseURLProvider) {
        self.authorisationService = authorisationService
        self.apiClient = apiClient
        self.responseValidator = responseValidator
        self.urlProvider = baseUrlProvider
    }

    @discardableResult
    func createEmptyFixedWifiSession(input: CreateSessionApi.Input, completion: @escaping (Result<CreateSessionApi.Output, Error>) -> Void) -> Cancellable {
        let url = urlProvider.baseAppURL.appendingPathComponent("realtime/sessions.json")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let inputJSONData = try! encoder.encode(input.session)
        let gzippedData = try! inputJSONData.gzipped()
        let sessionBase64String = gzippedData.base64EncodedString(options: [.lineLength76Characters, .endLineWithLineFeed])

        let apiInput = APIInput(session: sessionBase64String,
                                compression: input.compression)

        let apiPostData = try! encoder.encode(apiInput)
        request.httpBody = apiPostData

        do {
            try authorisationService.authorise(request: &request)
            return apiClient.requestTask(for: request) { [responseValidator, decoder] result, _ in
                completion(result.tryMap({
                    try responseValidator.validate(response: $0.response, data: $0.data)
                    return try decoder.decode(CreateSessionApi.Output.self, from: $0.data)
                }))
            }
        } catch {
            completion(.failure(error))
            return EmptyCancellable()
        }
    }
}
