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
    var locationTracker = LocationTrackerMock()
    var storage = MobileSessionStorageMock()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.locationTracker as LocationTracker }
        Resolver.test.register { self.storage as MobileSessionStorage }
        Resolver.test.register { self.activeSessionProvider as ActiveMobileSessionProvidingService }
    }
    
    func test_whenThereIsActiveSession_changesSessionStatusToDisconnected() throws {
        activeSessionProvider.setActiveSession(session: Session.mobileAirBeamMock, device: .init(name: "Device", uuid: "1234"))
        XCTAssertNotNil(activeSessionProvider.activeSession)
        sut.moveActiveSessionToStandaloneMode()
        XCTAssertEqual([SessionStatus.DISCONNECTED], storage.callHistory)
    }
    
    func test_whenThereIsActiveSessionWithLocation_stopLocationTracking() throws {
        activeSessionProvider.setActiveSession(session: Session.mobileAirBeamMock, device: .init(name: "Device", uuid: "1234"))
        XCTAssertNotNil(activeSessionProvider.activeSession)
        sut.moveActiveSessionToStandaloneMode()
        XCTAssertEqual([LocationTrackerMock.HistoryItem.stop], locationTracker.callHistory)
    }
    
    func test_whenThereIsActiveSessionWithoutLocation_doesntStopLocationTracking() throws {
        activeSessionProvider.setActiveSession(session: Session.mobileAirBeamLocationlessMock, device: .init(name: "Device", uuid: "1234"))
        XCTAssertNotNil(activeSessionProvider.activeSession)
        sut.moveActiveSessionToStandaloneMode()
        XCTAssertEqual([], locationTracker.callHistory)
    }
    
    func test_whenThereIsActiveSession_clearActiveSession() throws {
        activeSessionProvider.setActiveSession(session: Session.mobileAirBeamMock, device: .init(name: "Device", uuid: "1234"))
        XCTAssertNotNil(activeSessionProvider.activeSession)
        sut.moveActiveSessionToStandaloneMode()
        XCTAssertNil(activeSessionProvider.activeSession)
    }
    
    func test_whenThereIsNoActiveSession_doesntDoAnything() throws {
        activeSessionProvider.clearActiveSession()
        sut.moveActiveSessionToStandaloneMode()
        XCTAssertEqual([], locationTracker.callHistory)
        XCTAssertEqual([], storage.callHistory)
        XCTAssertNil(activeSessionProvider.activeSession)
    }
}

class ActiveMobileSessionProvidingServiceMock: ActiveMobileSessionProvidingService {
    private(set) var activeSession: MobileSession? = MobileSession(device: .init(name: "Device", uuid: "1234"), session: Session.mobileAirBeamMock)
    
    func setActiveSession(session: Session, device: NewBluetoothManager.BluetoothDevice) {
        activeSession = MobileSession(device: device, session: session)
    }
    
    func clearActiveSession() {
        activeSession = nil
    }
}

class LocationTrackerMock: LocationTracker {
    enum HistoryItem {
        case start
        case stop
    }
    var callHistory: [HistoryItem] = []
    var location: CurrentValueSubject<CLLocation?, Never> = .init(nil)
    func start() {
        callHistory.append(.start)
    }
    func stop() {
        callHistory.append(.stop)
    }
}

class MobileSessionStorageMock: MobileSessionStorage {
    var callHistory: [SessionStatus] = []
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) {
        callHistory.append(sessionStatus)
    }
    func updateSessionEndtime(_ endTime: Date, for uuid: AirCasting.SessionUUID) { }
}
