// Created by Lunar on 13/09/2021.
//

import XCTest
@testable import AirCasting

class AppBootstrapTests: XCTestCase {
    let firstRunProvider = FirstRunInfoProviderMock()
    let deauthorizer = DeauthorizerMock()
    lazy var bootstrap = AppBootstrap(firstRunInfoProvider: firstRunProvider, deauthorizable: deauthorizer)
    
    func test_whenFirstTimeRunningTheApp_clearsPreviousAuthorizationData() {
        firstRunProvider.isFirstAppLaunch = true
        bootstrap.bootstrap()
        XCTAssertEqual(deauthorizer.timesDeauthorized, 1)
    }
    
    func test_onSubsequentRunsOfTheApp_itDoesntClearAuthData() {
        firstRunProvider.isFirstAppLaunch = false
        bootstrap.bootstrap()
        XCTAssertEqual(deauthorizer.timesDeauthorized, 0)
    }
    
    func test_whenFirstTimeRunningTheApp_itRegistersAppRunWithFirstRunProvider() {
        firstRunProvider.isFirstAppLaunch = true
        bootstrap.bootstrap()
        XCTAssertEqual(firstRunProvider.timesAppLaunchRegistered, 1)
    }
    
    func test_onSubsequentRunsOfTheApp_itRegistersAppRunWithFirstRunProvider() {
        firstRunProvider.isFirstAppLaunch = false
        bootstrap.bootstrap()
        XCTAssertEqual(firstRunProvider.timesAppLaunchRegistered, 1)
    }
}

class FirstRunInfoProviderMock: FirstRunInfoProvidable {
    var isFirstAppLaunch: Bool = true
    private(set) var timesAppLaunchRegistered = 0
    
    func registerAppLaunch() {
        timesAppLaunchRegistered += 1
    }
}

class DeauthorizerMock: Deauthorizable {
    var timesDeauthorized = 0
    var errorToThrow: Error? = nil
    
    func deauthorize() throws {
        if let error = errorToThrow { throw error }
        timesDeauthorized += 1
    }
}
