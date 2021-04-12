//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import Combine

protocol APIClient {
    typealias APIPublisher = AnyPublisher<(data: Data, response: URLResponse), URLError>

    func fetchPublisher(for request: URLRequest) -> APIPublisher
}

extension URLSession: APIClient {
    func fetchPublisher(for request: URLRequest) -> APIPublisher {
        dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}

struct MissingTokenError: Swift.Error {}

extension URLRequest {
    #warning("throws error? Maybe better to have an access manager object")
    mutating func signWithToken() {
        try? trySigningWithToken()
    }

    mutating func trySigningWithToken() throws {
        guard let authToken = UserDefaults.authToken else {
            throw MissingTokenError()
        }
        let auth = "\(authToken):X".data(using: .utf8)!.base64EncodedString()
        setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
    }
}
