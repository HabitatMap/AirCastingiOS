// Created by Lunar on 21/07/2022.
//

import XCTest
import Combine
import Resolver
@testable import AirCasting

class WifiAwareSessionSynchronizerTests: ACTestCase {
    let userSettings = UserSettings(userDefaults: .init())
    let networkChecker = NetworkCheckerMock()

    override func setUp() {
        super.setUp()
        Resolver.test.register { self.userSettings as UserSettings }
        Resolver.test.register { self.networkChecker as NetworkChecker }
    }

    func test_triggersSyncWithCompletion_whenWifiSettingIsOff() throws {
        let controller = ControllerMock()
        let sut = WiFiAwareSessionSynchronizerProxy(controller: controller)
        
        userSettings.syncOnlyThroughWifi = false
        var completion = 0
        
        sut.triggerSynchronization() { completion += 1 }
        
        XCTAssertEqual(controller.triggerCounter, 1)
        XCTAssertEqual(completion, 1)

    }

    func test_doesntTriggerSyncButCallsCompletion_whenWifiSettingIsOnAndThereIsNoWifi() throws {
        let controller = ControllerMock()
        let sut = WiFiAwareSessionSynchronizerProxy(controller: controller)
        
        networkChecker.isUsingWifi = false
        userSettings.syncOnlyThroughWifi = true
        var completion = 0
        
        sut.triggerSynchronization() { completion += 1 }
        
        XCTAssertEqual(controller.triggerCounter, 0)
        XCTAssertEqual(completion, 1)
    }
    
    func test_triggersSyncWithCompletion_whenWifiSettingIsOnAndThereIsWifiConnection() throws {
        let controller = ControllerMock()
        let sut = WiFiAwareSessionSynchronizerProxy(controller: controller)
        
        networkChecker.isUsingWifi = true
        userSettings.syncOnlyThroughWifi = true
        var completion = 0
        
        sut.triggerSynchronization() { completion += 1 }
        
        XCTAssertEqual(controller.triggerCounter, 1)
        XCTAssertEqual(completion, 1)
    }
}

// MARK: - Test doubles

class ControllerMock: SessionSynchronizer {
    var syncInProgress: CurrentValueSubject<Bool, Never> = .init(false)
    
    var triggerCounter = 0
    
    func triggerSynchronization(options: SessionSynchronizationOptions, completion: (() -> Void)?) {
        triggerCounter += 1
        completion?()
    }
    
    func stopSynchronization() { }
    
    var errorStream: SessionSynchronizerErrorStream?
}

class NetworkCheckerMock: NetworkChecker {
    var connectionAvailable: Bool = false
    var isUsingWifi: Bool = false
}
