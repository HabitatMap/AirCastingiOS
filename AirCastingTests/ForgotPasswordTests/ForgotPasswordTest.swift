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
//        XCTAssertEqual(controllerMock.history.last, "test@email.com")
        #warning("Test not finished - concerned")
        //https://github.com/HabitatMap/AirCastingiOS/pull/67#discussion_r672974549
    }
    
    func test_varsConformsToStringsStruct() {
        XCTAssertEqual(defaultForgotPasswordViewModel.title, Strings.ForgotPassword.title)
//        XCTAssertEqual(defaultForgotPasswordViewModel.description, Strings.ForgotPassword.description)
        XCTAssertEqual(defaultForgotPasswordViewModel.actionTitle, Strings.ForgotPassword.actionTitle)
        XCTAssertEqual(defaultForgotPasswordViewModel.emailInputTitle, Strings.ForgotPassword.emailInputTitle)
    }
}
