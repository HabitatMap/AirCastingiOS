// Created by Lunar on 15/07/2021.
//

import Foundation

struct ForgotPasswordAlertViewModel {
    let message: String
    let title: String
    let actionTitle: String
}

protocol ForgotPasswordViewModel: ObservableObject {
    var title: String { get }
    var actionTitle: String { get }
    var cancelTitle: String { get }
    var emailInputTitle: String { get }
    var alert: ForgotPasswordAlertViewModel? { get set }
    
    func emailChanged(to email: String)
    func sendNewPassword()
}
