// Created by Lunar on 16/07/2021.
//

import XCTest
@testable import AirCasting

class ForgotPasswordViewModelTest: XCTestCase {
    
    private var defaultForgotPasswordViewModel: DefaultForgotPasswordViewModel!
    
    override func setUp() {
        defaultForgotPasswordViewModel = DefaultForgotPasswordViewModel(controller: MockForgotPasswordController())
    }
    
    func test_isEmailChanging() {
        defaultForgotPasswordViewModel.emailChanged(to: "test@email.com")
        XCTAssertEqual(defaultForgotPasswordViewModel.email, "test@email.com")
        XCTAssertNotEqual(defaultForgotPasswordViewModel.email, "@email.com")
    }
    
    func test_varsConformsToStringsStruct() {
        XCTAssertEqual(defaultForgotPasswordViewModel.title, Strings.ForgotPassword.title)
        XCTAssertEqual(defaultForgotPasswordViewModel.description, Strings.ForgotPassword.description)
        XCTAssertEqual(defaultForgotPasswordViewModel.actionTitle, Strings.ForgotPassword.actionTitle)
        XCTAssertEqual(defaultForgotPasswordViewModel.emailInputTitle, Strings.ForgotPassword.emailInputTitle)
    }
}
