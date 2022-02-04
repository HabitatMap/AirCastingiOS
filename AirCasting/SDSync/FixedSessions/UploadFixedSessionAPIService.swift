// Created by Lunar on 29/11/2021.
//

import Foundation
import Combine
import Gzip
import Resolver

// TODO: Hide this behind protocol
class UploadFixedSessionAPIService {

    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var authorisationService: RequestAuthorisationService
    
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
        let formatter = DateFormatters.SessionUploadService.encoderDateFormatter
        $0.dateEncodingStrategy = .formatted(formatter)
        return $0
    }(JSONEncoder())
    
    @discardableResult
    func uploadFixedSession(input: UploadFixedMeasurementsParams, completion: @escaping (Result<APIOutput, Error>) -> Void) -> Cancellable {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/realtime/measurements")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let inputJSONData = try! encoder.encode(input)
        let gzippedData = try! inputJSONData.gzipped()
        let sessionBase64String = gzippedData.base64EncodedString(options: [.lineLength76Characters, .endLineWithLineFeed])
        let apiInput = APIInput(data: sessionBase64String)
        let apiPostData = try! encoder.encode(apiInput)
        request.httpBody = apiPostData
        do {
            try authorisationService.authorise(request: &request)
            return apiClient.requestTask(for: request) { [responseValidator] result, _ in
                completion(result.tryMap({
                    try responseValidator.validate(response: $0.response, data: $0.data)
                    return APIOutput()
                }))
            }
        } catch {
            completion(.failure(error))
            return EmptyCancellable()
        }
    }
}

extension UploadFixedSessionAPIService {
    
    struct UploadFixedMeasurementsParams: Encodable {
        let session_uuid: String
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
        let measurements: [CSVMeasurement]
    }
    
    fileprivate struct APIInput: Encodable {
        let data: String
        var compression: Bool = true
    }
    
    struct APIOutput: Codable {}
}
