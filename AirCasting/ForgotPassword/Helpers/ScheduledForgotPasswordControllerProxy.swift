// Created by Lunar on 15/07/2021.
//

import Foundation

final class ScheduledForgotPasswordControllerProxy: ForgotPasswordController {
    private let controller: ForgotPasswordController
    private let queue: DispatchQueue
    
    init(controller: ForgotPasswordController, queue: DispatchQueue) {
        self.controller = controller
        self.queue = queue
    }
    
    func resetPassword(login: String, completion: @escaping (Result<Void, ForgotPasswordError>) -> Void) {
        controller.resetPassword(login: login) { [weak self] result in
            self?.queue.async {
                completion(result)
            }
        }
    }
}
