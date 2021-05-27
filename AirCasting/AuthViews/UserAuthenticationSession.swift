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
        try keychainStorage.removeValue(forKey: Self.authenticationTokenKey)
        self.token = nil
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

protocol LogoutController {
    func logout() throws
}

final class DefaultLogoutController: LogoutController {
    let userAuthenticationSession: UserAuthenticationSession
    let sessionStorage: SessionStorage
    let microphoneManager: MicrophoneManager

    init(userAuthenticationSession: UserAuthenticationSession, sessionStorage: SessionStorage, microphoneManager: MicrophoneManager) {
        self.userAuthenticationSession = userAuthenticationSession
        self.sessionStorage = sessionStorage
        self.microphoneManager = microphoneManager
    }

    func logout() throws {
        Log.info("Logging out. Cancelling all pending requests")
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        if microphoneManager.isRecording {
            Log.info("Canceling recording session")
            try? microphoneManager.stopRecording()
        }
        Log.info("Clearing user credentials")
        try userAuthenticationSession.deauthorize()
        do {
            try sessionStorage.clearAllSessionSilently()
        } catch {
            assertionFailure("Failed to clear sessions \(error)")
        }
    }
}

#if DEBUG
final class FakeLogoutController: LogoutController {
    func logout() throws {
        fatalError("Should not be called. Only for preview")
    }
}
#endif
