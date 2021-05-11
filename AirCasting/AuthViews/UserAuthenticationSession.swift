// Created by Lunar on 18/04/2021.
//

import Foundation

final class UserAuthenticationSession: ObservableObject {
    private static let authenticationTokenKey = "AuthenticationToken"
    private let keychainStorage = KeychainStorage(service: Bundle.main.bundleIdentifier!)

    @Published private(set) var isLoggedIn: Bool = false
    private(set) var token: String? {
        didSet {
            isLoggedIn = token != nil
        }
    }

    init() {
        do {
            token = try keychainStorage.string(forKey: Self.authenticationTokenKey)
            isLoggedIn = token != nil
        } catch {
            assertionFailure("Failed to fetch token \(error)")
        }
    }

    func authorise(with token: String) throws {
        try keychainStorage.setString(token, forKey: Self.authenticationTokenKey)
        self.token = token
    }

    func deauthorize() throws {
        self.token = nil
        try keychainStorage.removeValue(forKey: Self.authenticationTokenKey)
    }
}

struct MissingTokenError: Swift.Error {}

extension UserAuthenticationSession: RequestAuthorisationService {
    @discardableResult
    func authorise(request: inout URLRequest) throws -> URLRequest {
        guard let authToken = token else {
            throw MissingTokenError()
        }
        let auth = "\(authToken):X".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        return request
    }
}
