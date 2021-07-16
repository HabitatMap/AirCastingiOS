// Created by Lunar on 15/07/2021.
//

import Foundation

enum ResetPasswordServiceError: Error {
    case ioFailure(underlyingError: Error)
}

protocol ResetPasswordService {
    func resetPassword(login: String, completion: @escaping (Result<Void, ResetPasswordServiceError>) -> Void)
}

class MockResetPasswordService: ResetPasswordService {
    func resetPassword(login: String, completion: @escaping (Result<Void, ResetPasswordServiceError>) -> Void) {
        completion(.success(()))
    }
}
