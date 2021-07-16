// Created by Lunar on 15/07/2021.
//

import Foundation

final class DefaultForgotPasswordViewModel: ForgotPasswordViewModel {
    let title = Strings.ForgotPassword.title
    let description = Strings.ForgotPassword.description
    let actionTitle = Strings.ForgotPassword.actionTitle
    let emailInputTitle = Strings.ForgotPassword.emailInputTitle
    
    var alert: ForgotPasswordAlertViewModel? = nil { willSet { objectWillChange.send() } }
    
    var onChangeAlertVisibility: ((Bool) -> Void)?
    
    var email: String = ""
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
                self.alert = .init(message: "Email was sent. Please check your inbox for the details.", title: "Email response", actionTitle: "OK")
            case .failure:
                self.alert = .init(message: "Something went wrong, please try again", title: "Email response", actionTitle: "OK")
            }
        }
    }
}
