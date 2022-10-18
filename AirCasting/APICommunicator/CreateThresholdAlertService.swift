// Created by Lunar on 08/08/2022.
//

import Foundation
import Resolver

protocol CreateThresholdAlertService {
    func createAlert(sessionUUID: SessionUUID, sensorName: String, thresholdValue: String, frequency: ThresholdAlertFrequency, completion: @escaping (Result<AlertId, Error>) -> ())
}

struct AlertId: Decodable {
    let id: Int
}

class DefaultCreateThresholdAlertAPI: CreateThresholdAlertService {
    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var authorisationService: RequestAuthorisationService
    
    struct Params: Encodable {
        private let data: Nested
        
        struct Nested: Encodable {
            let sensorName: String
            let sessionUuid: String
            let thresholdValue: String
            let frequency: String
            let timezoneOffset: String
        }
        
        init(sessionUUID: SessionUUID, sensorName: String, thresholdValue: String, frequency: ThresholdAlertFrequency, timezoneOffset: Int) {
            self.data = Nested(sensorName: sensorName, sessionUuid: sessionUUID.rawValue, thresholdValue: thresholdValue, frequency: String(frequency.rawValue), timezoneOffset: String(timezoneOffset))
        }
    }
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    func createAlert(sessionUUID: SessionUUID, sensorName: String, thresholdValue: String, frequency: ThresholdAlertFrequency, completion: @escaping (Result<AlertId, Error>) -> ()) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/fixed/threshold_alerts")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        
        Log.info("## \(timezoneOffset)")
        let params = Params(sessionUUID: sessionUUID, sensorName: sensorName, thresholdValue: thresholdValue, frequency: frequency, timezoneOffset: timezoneOffset)
        
        do {
            request.httpBody = try encoder.encode(params)
            try authorisationService.authorise(request: &request)
        } catch {
            completion(.failure(error))
        }

        apiClient.requestTask(for: request) { [responseValidator, decoder] result, request in
            switch result {
            case .success(let response):
                do {
                    try responseValidator.validate(response: response.response, data: response.data)
                    let alertData = try decoder.decode(AlertId.self, from: response.data)
                    completion(.success(alertData))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
