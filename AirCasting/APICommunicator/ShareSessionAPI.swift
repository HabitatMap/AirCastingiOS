// Created by Lunar on 05/01/2022.
//

import Foundation
import Resolver

enum ShareSessionAPIError: Error {
    case creatingURLComponentsError
    case requestError(Error)
}

protocol ShareSessionAPIServices {
    func sendSession(email: String, uuid: String, completion: @escaping (Result<Void, ShareSessionAPIError>) -> Void)
}

struct ShareSessionApi: ShareSessionAPIServices {
    @Injected private var urlProvider: URLProvider
    
    func sendSession(email: String, uuid: String, completion: @escaping (Result<Void, ShareSessionAPIError>) -> Void) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/sessions/export_by_uuid.json")
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completion(.failure(.creatingURLComponentsError))
            return
        }
        components.queryItems = [URLQueryItem(name: "email", value: email), URLQueryItem(name: "uuid", value: uuid)]
        
        guard let requestUrl = components.url else {
            completion(.failure(.creatingURLComponentsError))
            return
        }
        
        var request = URLRequest.jsonGET(url: url)
        request.httpShouldHandleCookies = false
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let apiClient = URLSession.shared
        
        _ = apiClient.requestTask(for: request) { result, _ in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.requestError(error)))
            }
        }
    }
}
