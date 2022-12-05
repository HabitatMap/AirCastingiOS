// Created by Lunar on 17/11/2022.
//

import XCTest
import Resolver
import CoreLocation
import Combine
@testable import AirCasting

final class SessionManagingReconnectionControllerTests: ACTestCase {
    lazy var sut = SessionManagingReconnectionController()
    var activeSessionProvider = ActiveMobileSessionProvidingServiceMock()
    let standaloneController = StandaloneModeControllerSpy()
    var bluetoothSessionController = BluetoothSessionRecordingControllerMock()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.activeSessionProvider as ActiveMobileSessionProvidingService }
        Resolver.test.register { self.standaloneController as StandaloneModeController }
        Resolver.test.register { self.bluetoothSessionController as BluetoothSessionRecordingController }
    }

    func testShouldReconnect_withActiveSessionWithTheDevice_returnsTrue() {
        let device = NewBluetoothManager.BluetoothDevice(name: "Device", uuid: "123")
        activeSessionProvider.setActiveSession(session: .mobileAirBeamMock, device: device)
        XCTAssertTrue(sut.shouldReconnect(to: device))
    }
    
    func testShouldReconnect_withActiveSessionWithDifferentDevice_returnsFalse() {
        let device = NewBluetoothManager.BluetoothDevice(name: "Device", uuid: "123")
        activeSessionProvider.setActiveSession(session: .mobileAirBeamMock, device: .init(name: "Device2", uuid: "456"))
        XCTAssertFalse(sut.shouldReconnect(to: device))
    }
    
    func testShouldReconnect_withNoActiveSession_returnsFalse() {
        let device = NewBluetoothManager.BluetoothDevice(name: "Device", uuid: "123")
        activeSessionProvider.clearActiveSession()
        XCTAssertFalse(sut.shouldReconnect(to: device))
    }
    
    func testDidReconnect_resumesRecordingWithRightDevice() {
        let device = NewBluetoothManager.BluetoothDevice(name: "Device", uuid: "123")
        sut.didReconnect(to: device)
        XCTAssertEqual(bluetoothSessionController.callsHistory, [.resume(device: device)])
    }
    
    func testDidFailtToReconnect_movesSessionToStandaloneMode() {
        let device = NewBluetoothManager.BluetoothDevice(name: "Device", uuid: "123")
        activeSessionProvider.setActiveSession(session: .mobileAirBeamMock, device: device)
        sut.didFailToReconnect(to: device)
        XCTAssertEqual(standaloneController.moveToStandaloneModeCount, 1)
    }
}

class StandaloneModeControllerSpy: StandaloneModeController {
    var moveToStandaloneModeCount = 0
    func moveActiveSessionToStandaloneMode() {
        moveToStandaloneModeCount += 1
    }
}
