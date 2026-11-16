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
    var bluetoothSessionController = BluetoothSessionRecordingControllerMock()

    override func setUp() {
        super.setUp()
        Resolver.test.register { self.activeSessionProvider as ActiveMobileSessionProvidingService }
        Resolver.test.register { self.bluetoothSessionController as BluetoothSessionRecordingController }
        Resolver.test.register { MeasurementsSavingServiceMock() as MeasurementsSavingService }
        Resolver.test.register { MobileSessionRecordingStorageMock() as MobileSessionRecordingStorage }
    }

    func testShouldReconnect_withActiveSessionWithTheDevice_returnsTrue() {
        let device = BluetoothDeviceMock(name: "Device", uuid: "123")
        activeSessionProvider.setActiveSession(session: .mobileAirBeamMock, device: device)
        XCTAssertTrue(sut.shouldReconnect(to: device))
    }

    func testShouldReconnect_withActiveSessionWithDifferentDevice_returnsFalse() {
        let device = BluetoothDeviceMock(name: "Device", uuid: "123")
        activeSessionProvider.setActiveSession(session: .mobileAirBeamMock, device: BluetoothDeviceMock(name: "Device2", uuid: "456"))
        XCTAssertFalse(sut.shouldReconnect(to: device))
    }

    func testShouldReconnect_withNoActiveSession_returnsFalse() {
        let device = BluetoothDeviceMock(name: "Device", uuid: "123")
        activeSessionProvider.clearActiveSession()
        XCTAssertFalse(sut.shouldReconnect(to: device))
    }

    func testDidReconnect_resumesRecordingWithRightDevice() {
        let device = BluetoothDeviceMock(name: "Device", uuid: "123")
        sut.didReconnect(to: device)
        XCTAssertEqual(bluetoothSessionController.callsHistory, [.resume(device: device)])
    }

}

class MobileSessionRecordingStorageMock: MobileSessionRecordingStorage {
    func accessStorage(_ task: @escaping (HiddenMobileSessionRecordingStorage) -> Void) { }
}
