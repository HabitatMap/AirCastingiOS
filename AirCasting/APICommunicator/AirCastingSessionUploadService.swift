// Created by Lunar on 13/06/2021.
//

import Foundation
import Combine
import Gzip
import CoreLocation

final class AirCastingSessionUploadService: SessionUploadService {
    private let client: APIClient
    private let authorization: RequestAuthorisationService
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    init(client: APIClient = URLSession.shared, authorization: RequestAuthorisationService) {
        self.client = client
        self.authorization = authorization
    }
    
    func upload(session: SessionsSynchronization.SessionUploadData) -> Future<Void, Error> {
        .init { [client, authorization, encoder] promise in
            let url = URL(string: "http://aircasting.org/api/sessions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            do {
                try request.httpBody = encoder.encode(session)
                try authorization.authorise(request: &request)
            } catch {
                promise(.failure(error))
            }
            client.requestTask(for: request) { result, request in
                switch result {
                case .success: promise(.success(()))
                case .failure(let error): promise(.failure(error))
                }
            }
        }
    }
}
