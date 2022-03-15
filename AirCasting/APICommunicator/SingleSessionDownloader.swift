// Created by Lunar on 10/03/2022.
//

import Foundation
import Resolver

protocol SingleSessionDownloader {
    func downloadSessionNameAndTags(with sessionUUID: SessionUUID, completion: @escaping (Result<SessionWithNameAndTags, Error>) -> ())
}

struct SessionWithNameAndTags: Decodable {
    let uuid: SessionUUID
    let title: String
    let tagList: String
}

class DefaultSingleSessionDownloader: SingleSessionDownloader {
    @Injected private var urlProvider: URLProvider
    @Injected private var apiClient: APIClient
    @Injected private var responseValidator: HTTPResponseValidator
    @Injected private var authorisationService: RequestAuthorisationService
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func downloadSessionNameAndTags(with sessionUUID: SessionUUID, completion: @escaping (Result<SessionWithNameAndTags, Error>) -> ()) {
        let urlComponentPart = urlProvider.baseAppURL.appendingPathComponent("api/user/sessions/update_session.json")
        var urlComponents = URLComponents(string: urlComponentPart.absoluteString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "uuid", value: sessionUUID.rawValue)
        ]
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            try authorisationService.authorise(request: &request)
        } catch {
            completion(.failure(error))
        }

        apiClient.requestTask(for: request) { [responseValidator, decoder] result, request in
            switch result {
            case .success(let response):
                do {
                    try responseValidator.validate(response: response.response, data: response.data)
                    let sessionData = try decoder.decode(SessionWithNameAndTags.self, from: response.data)
                    completion(.success(sessionData))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
