// Created by Lunar on 15/07/2021.
//

import Foundation

final class EmailForgotPasswordController: ForgotPasswordController {
    
    private let resetPasswordService: ResetPasswordService
    
    init(resetPasswordService: ResetPasswordService) {
        self.resetPasswordService = resetPasswordService
    }
    
    func resetPassword(login: String, completion: @escaping (Result<Void, ForgotPasswordError>) -> Void) {
        resetPasswordService.resetPassword(login: login) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(self.createError(from: error)))
            }
        }
    }
    
    private func createError(from serviceError: ResetPasswordServiceError) -> ForgotPasswordError {
        return .couldntComplete
    }
}
