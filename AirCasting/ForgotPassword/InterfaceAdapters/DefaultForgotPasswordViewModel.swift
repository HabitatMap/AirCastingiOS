// Created by Lunar on 15/07/2021.
//

import Foundation

final class DefaultForgotPasswordViewModel: ForgotPasswordViewModel {
    let title = Strings.ForgotPassword.title
    let actionTitle = Strings.Commons.ok
    let cancelTitle = Strings.Commons.cancel
    let emailInputTitle = Strings.ForgotPassword.emailInputTitle
    
    var alert: ForgotPasswordAlertViewModel? = nil { willSet { objectWillChange.send() } }
    
    private var email: String = ""
    private let controller: ForgotPasswordController
    
    init(controller: ForgotPasswordController) {
        self.controller = controller
    }
    
    func emailChanged(to email: String) {
        self.email = email
    }
    
    func sendNewPassword() {
        controller.resetPassword(login: email) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.alert = .init(message: Strings.ForgotPassword.newPasswordSuccessMessage, title: Strings.ForgotPassword.newPasswordSuccessTitle, actionTitle: Strings.Commons.ok)
            case .failure:
                self.alert = .init(message: Strings.ForgotPassword.newPasswordFailureMessage, title: Strings.ForgotPassword.newPasswordFailureTitle, actionTitle: Strings.Commons.ok)
            }
        }
    }
}
