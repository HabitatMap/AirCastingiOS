// Created by Lunar on 17/11/2022.
//

import XCTest
import Resolver
import CoreLocation
import Combine
@testable import AirCasting

final class DefaultStandaloneModeContollerTests: ACTestCase {
    lazy var sut = DefaultStandaloneModeContoller()
    var activeSessionProvider = ActiveMobileSessionProvidingServiceMock()
    var sessionRecordingController = BluetoothSessionRecordingControllerMock()

    override func setUp() {
        super.setUp()
        Resolver.test.register { self.sessionRecordingController as BluetoothSessionRecordingController }
        Resolver.test.register { self.storage as MobileSessionFinishingStorage }
        Resolver.test.register { self.activeSessionProvider as ActiveMobileSessionProvidingService }
    }

    func test_whenThereIsActiveSessionWithLocation_stopRecordingSession() throws {
        activeSessionProvider.setActiveSession(session: Session.mobileAirBeamMock, device: BluetoothDeviceMock(name: "Device", uuid: "1234"))
        XCTAssertNotNil(activeSessionProvider.activeSession)
        sut.moveActiveSessionToStandaloneMode()
        XCTAssertEqual([BluetoothSessionRecordingControllerMock.HistoryItem.stop(uuid: Session.mobileAirBeamMock.uuid)], sessionRecordingController.callsHistory)
        XCTAssertEqual([SessionStatus.DISCONNECTED], storage.hiddenStorage.callHistory)
    }

    func test_whenThereIsNoActiveSession_doesntDoAnything() throws {
        activeSessionProvider.clearActiveSession()
        sut.moveActiveSessionToStandaloneMode()
        XCTAssertEqual([], sessionRecordingController.callsHistory)
        XCTAssertNil(activeSessionProvider.activeSession)
    }
}

class MobileSessionStorageMock: MobileSessionFinishingStorage {
    let hiddenStorage = HiddenStorage()
    func accessStorage(_ task: @escaping (AirCasting.HiddenMobileSessionFinishingStorage) -> Void) {
        task(hiddenStorage)
    }

    class HiddenStorage: HiddenMobileSessionFinishingStorage {
        var callHistory: [SessionStatus] = []
        func save() throws {}
        func updateSessionStatus(_ sessionStatus: AirCasting.SessionStatus, for sessionUUID: AirCasting.SessionUUID) throws { callHistory.append(sessionStatus) }
        func updateSessionEndtime(_ endTime: Date, for sessionUUID: AirCasting.SessionUUID) throws { }
    }
}
