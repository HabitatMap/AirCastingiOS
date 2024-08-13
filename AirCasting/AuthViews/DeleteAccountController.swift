// Created by Lunar on 26/04/2022.
//

import Foundation
import Resolver

protocol DeleteAccountController {
    func deleteAccount(confirmationCode: String, completion: @escaping (Result<Void, Error>) -> Void)
    func sendCode(completion: @escaping (Result<Void, Error>) -> Void)
}

final class DefaultDeleteAccountController: DeleteAccountController {
    @Injected private var authorisation: RequestAuthorisationService
    @Injected private var urlProvider: URLProvider
    @Injected private var client: APIClient
    @Injected private var removeDataController: RemoveDataController

    private let responseHandler = AuthorizationHTTPResponseHandler()
    
    
    func sendCode(completion: @escaping (Result<Void, Error>) -> Void) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/user/delete_account_send_code")
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            try authorisation.authorise(request: &request)
            client.requestTask(for: request) { [responseHandler] result, _ in
                switch responseHandler.handle(result) {
                case .success(_):
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteAccount(confirmationCode: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/user/delete_account_confirm")
        do {
            let params = ["code": confirmationCode]
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            try authorisation.authorise(request: &request)
            client.requestTask(for: request) { [responseHandler] result, _ in
                switch responseHandler.handle(result) {
                case .success(_):
                    self.removeDataController.removeData()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
