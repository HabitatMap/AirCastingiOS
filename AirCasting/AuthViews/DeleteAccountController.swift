// Created by Lunar on 26/04/2022.
//

import Foundation
import Resolver

protocol DeleteAccountController {
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void)
}

final class DefaultDeleteAccountController: DeleteAccountController {
    @Injected private var authorisation: RequestAuthorisationService
    @Injected private var urlProvider: URLProvider
    @Injected private var client: APIClient
    @Injected private var removeDataController: RemoveDataController

    private let responseHandler = AuthorizationHTTPResponseHandler()
    
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/user.json")
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
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
