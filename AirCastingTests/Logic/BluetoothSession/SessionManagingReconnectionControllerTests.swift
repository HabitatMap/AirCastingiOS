// Created by Lunar on 17/11/2022.
//

import XCTest
import Resolver
import CoreLocation
import Combine
@testable import AirCasting

final class SessionManagingReconnectionControllerTests: ACTestCase {
    let sut = DefaultStandaloneModeContoller()
    var activeSessionProvider = ActiveMobileSessionProvidingServiceMock()
    let standaloneController = StandaloneModeControllerMock()
    var bluetoothSessionController = BluetoothSessionRecordingControllerMock()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.activeSessionProvider as ActiveMobileSessionProvidingService }
        Resolver.test.register { self.bluetoothSessionController as BluetoothSessionRecordingController }
    }

    func TOBEDONEtestExample() throws {
        
    }
}

class StandaloneModeControllerMock: StandaloneModeController {
    func moveActiveSessionToStandaloneMode() {
        
    }
}

class BluetoothSessionRecordingControllerMock: BluetoothSessionRecordingController {
    enum HistoryItem {
        case start
        case resume
        case stop
    }
    
    var callsHistory: [HistoryItem] = []
    
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) { callsHistory.append(.start) }
    func resumeRecording(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) { callsHistory.append(.resume) }
    func stopRecordingSession(with uuid: AirCasting.SessionUUID, databaseChange: (AirCasting.MobileSessionStorage) -> Void) { callsHistory.append(.stop) }
}
