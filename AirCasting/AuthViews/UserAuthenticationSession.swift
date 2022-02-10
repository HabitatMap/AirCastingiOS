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
            isLoggedIn = user != nil
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

protocol LogoutController {
    func logout(onEnd: @escaping () -> Void) throws
}

final class DefaultLogoutController: LogoutController {
    @Injected private var deauthorizer: Deauthorizable
    @Injected private var microphoneManager: MicrophoneManager
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var dataEraser: DataEraser

    func logout(onEnd: @escaping () -> Void) throws {
        if sessionSynchronizer.syncInProgress.value {
            var subscription: AnyCancellable?
            subscription = sessionSynchronizer.syncInProgress.receive(on: DispatchQueue.main).sink { [weak self] value in
                guard value == false else { return }
                self?.deleteEverything()
                subscription?.cancel()
                onEnd()
            }
            return
        }
        // For logout we only care about uploading sessions before we remove everything
        sessionSynchronizer.triggerSynchronization(options: [.upload], completion: {
            DispatchQueue.main.async { self.deleteEverything(); onEnd() }
        })
    }
    
    func deleteEverything() {
        Log.info("[LOGOUT] Cancelling all pending requests")
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        if microphoneManager.isRecording {
            Log.info("[LOGOUT] Canceling recording session")
            microphoneManager.stopRecording()
        }
        Log.info("[LOGOUT] Clearing user credentials")
        do {
            try deauthorizer.deauthorize()
            dataEraser.eraseAllData(completion: { [weak self] result in
                if case let .failure(error) = result {
                    self?.failLogout(with: error)
                }
            })
        } catch {
            failLogout(with: error)
        }
    }
    
    private func failLogout(with error: Error) {
        assertionFailure("[LOGOUT] Failed to log out \(error)")
    }
}
