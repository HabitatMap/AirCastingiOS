// Created by Lunar on 15/07/2021.
//

import Foundation

enum ForgotPasswordError: Error {
    case couldntComplete
}

protocol ForgotPasswordController {
    func resetPassword(login: String, completion: @escaping (Result<Void, ForgotPasswordError>) -> Void)
}

class MockForgotPasswordController: ForgotPasswordController {
    func resetPassword(login: String, completion: @escaping (Result<Void, ForgotPasswordError>) -> Void) {
        completion(.success(()))
    }
}
