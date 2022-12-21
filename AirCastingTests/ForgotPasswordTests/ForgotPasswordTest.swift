// Created by Lunar on 16/07/2021.
//

import XCTest
@testable import AirCasting

class ForgotPasswordViewModelTest: ACTestCase {
    
    private var defaultForgotPasswordViewModel: DefaultForgotPasswordViewModel!
    private let controller = MockForgotPasswordController()
    
    override func setUp() {
        defaultForgotPasswordViewModel = DefaultForgotPasswordViewModel(controller: controller)
    }
    
    func test_isEmailChanging() {
        defaultForgotPasswordViewModel.emailChanged(to: "test@email.com")
        defaultForgotPasswordViewModel.sendNewPassword()
        XCTAssertEqual(controller.loginsHistory.last, "test@email.com")
    }
    
    func test_varsConformsToStringsStruct() {
        XCTAssertEqual(defaultForgotPasswordViewModel.title, Strings.ForgotPassword.title)
        XCTAssertEqual(defaultForgotPasswordViewModel.actionTitle, Strings.Commons.ok)
        XCTAssertEqual(defaultForgotPasswordViewModel.emailInputTitle, Strings.ForgotPassword.emailInputTitle)
    }
}
