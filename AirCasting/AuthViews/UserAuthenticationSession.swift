// Created by Lunar on 18/04/2021.
//

import Foundation
import Combine
import Resolver

struct User: Hashable {
    let id: Int
    let username: String
    let token: String
    let email: String
}

protocol Deauthorizable {
    func deauthorize() throws
}

protocol DataEraser {
    func eraseAllData(completion: ((Result<Void, Error>) -> Void)?)
}

final class UserAuthenticationSession: Deauthorizable, ObservableObject {

    private static let userProfileKey = "UserProfileKey"
    private let keychainStorage = KeychainStorage(service: Bundle.main.bundleIdentifier!)

    @Published private(set) var isLoggedIn: Bool = false
    
    var token: String? { user?.token }

    private(set) var user: User? {
        didSet {
            DispatchQueue.main.async {
                self.isLoggedIn = self.user != nil
            }
        }
    }

    init() {
        do {
            if let data = try keychainStorage.data(forKey: Self.userProfileKey) {
                let codableUser = try JSONDecoder().decode(CodableUser.self, from: data)
                user = User(id: codableUser.id, username: codableUser.username, token: codableUser.token, email: codableUser.email)
                isLoggedIn = true
            } else {
                isLoggedIn = false
            }
        } catch {
            assertionFailure("Failed to fetch token \(error)")
        }
    }

    func authorise(_ user: User) throws {
        let jsonEncoder = JSONEncoder()
        let codableUser = CodableUser(id: user.id, username: user.username, token: user.token, email: user.email)
        try keychainStorage.setValue(value: try jsonEncoder.encode(codableUser), forKey: Self.userProfileKey)
        self.user = user
    }

    func deauthorize() throws {
        try keychainStorage.removeValue(forKey: Self.userProfileKey)
        self.user = nil
    }

    private struct CodableUser: Codable {
        let id: Int
        let username: String
        let token: String
        let email: String
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
