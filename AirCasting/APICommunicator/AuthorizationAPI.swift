//
//  AuthorizationAPI.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import Foundation
import Combine
import Resolver

class AuthorizationAPI {
    struct SignupUserInput: Encodable, Hashable {
        let email: String
        let username: String
        let password: String
        let send_emails: Bool
    }
    
    struct SigninUserInput: Decodable, Hashable {
        let username: String
        let password: String
    }

    struct UserProfile: Decodable, Hashable {
        let id: Int
        let authentication_token: String
        let username: String
        let email: String
    }
}

enum AuthorizationError: Error, LocalizedError, Identifiable {
    case other(Swift.Error)
    case timeout(Swift.Error)
    case noConnection(Swift.Error)
    case usernameTaken(Any)
    case emailTaken(Any)
    case invalidCredentials(Any)

    var id: ObjectIdentifier {
        (self as NSError).id
    }

    var localizedDescription: String {
        switch self {
        case .other:
            return NSLocalizedString("Unknown error occurred. Try again.", comment: "Unknown login message failure")
        case .timeout:
            return NSLocalizedString("It looks like the server is taking to long to respond. Try again later.", comment: "time out login message failure")
        case .noConnection:
            return NSLocalizedString("Please, make sure your device is connected to the internet.", comment: "connection failure login message failure")
        case .usernameTaken, .emailTaken, .invalidCredentials:
            return NSLocalizedString("Email or profile name is already in use. Please try again.", comment: "connection failure login message failure")
        }
    }
    
    var errorDescription: String? { localizedDescription }
}

final class AuthorizationAPIService {

    private struct SignupAPIInput: Encodable, Hashable {
        let user: AuthorizationAPI.SignupUserInput
    }
    
    @Injected private var apiClient: APIClient
    private let responseHandler = AuthorizationHTTPResponseHandler()
    let url: URL

    private lazy var decoder: JSONDecoder = JSONDecoder()
    private lazy var encoder = JSONEncoder()

    init() {
        let urlProvider = Resolver.resolve(URLProvider.self)
        self.url = urlProvider.baseAppURL.appendingPathComponent("api/user.json")
    }

    @discardableResult
    func createAccount(input: AuthorizationAPI.SignupUserInput, completion: @escaping (Result<AuthorizationAPI.UserProfile, AuthorizationError>) -> Void) -> Cancellable{
        var request = URLRequest(url: url)
        request.httpBody = try! encoder.encode(SignupAPIInput(user: input))
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpShouldHandleCookies = false
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return apiClient.requestTask(for: request) { [responseHandler, decoder] result, _ in
            switch responseHandler.handle(result) {
            case .success(let response):
                do {
                    completion(.success(try decoder.decode(AuthorizationAPI.UserProfile.self, from: response.data)))
                } catch {
                    completion(.failure(.other(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    @discardableResult
    func signIn(input: AuthorizationAPI.SigninUserInput, completion: @escaping (Result<AuthorizationAPI.UserProfile, AuthorizationError>) -> Void) -> Cancellable{
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpShouldHandleCookies = false
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let base64input = Data("\(input.username):\(input.password)".utf8).base64EncodedString()
        request.addValue("Basic \(base64input)", forHTTPHeaderField: "Authorization")
        return apiClient.requestTask(for: request) { [responseHandler, decoder] result, _ in
            switch responseHandler.handle(result) {
            case .success(let response):
                do {
                    completion(.success(try decoder.decode(AuthorizationAPI.UserProfile.self, from: response.data)))
                } catch {
                    completion(.failure(.other(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

final class AuthorizationHTTPResponseHandler {
    lazy var decoder = JSONDecoder()
    private struct AuthorizationErrorResponse: Decodable {
        let username: [String]?
        let email: [String]?
    }

    func handle(_ result: Result<(data: Data, response: HTTPURLResponse), Error>) -> Result<(data: Data, response: HTTPURLResponse), AuthorizationError> {
        switch result {
        case .success((let data, let response)):
            switch response.statusCode {
            case 200..<300:
                return .success((data: data, response: response))
            case 422:
                do {
                    let response = try decoder.decode(AuthorizationErrorResponse.self, from: data)
                    if response.email?.contains("has already been taken") ?? false {
                        return .failure(.emailTaken(response))
                    }
                    if response.username?.contains("has already been taken") ?? false {
                        return .failure(.usernameTaken(response))
                    }
                    return .failure(.other(URLError(.badServerResponse, userInfo: ["data": data, "response": response])))
                } catch {
                    return .failure(.other(error))
                }
            default:
                return .failure(.other(URLError(.badServerResponse, userInfo: ["data": data, "response": response])))
            }
        case .failure(let error):
            switch error {
            case URLError.timedOut:
                return .failure(.timeout(error))
            case URLError.notConnectedToInternet, URLError.networkConnectionLost:
                return .failure(.noConnection(error))
            default:
                return .failure(.other(error))
            }
        }
    }
}
