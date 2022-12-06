// Created by Lunar on 05/12/2022.
//

import Foundation
@testable import AirCasting

class BluetoothSessionRecordingControllerMock: BluetoothSessionRecordingController {
    enum HistoryItem: Equatable {
        static func == (lhs: BluetoothSessionRecordingControllerMock.HistoryItem, rhs: BluetoothSessionRecordingControllerMock.HistoryItem) -> Bool {
            switch (lhs, rhs) {
            case (.start(session: let lhsSession, device: let lhsDevice), .start(session: let rhsSession, device: let rhsDevice)): return lhsSession.uuid == rhsSession.uuid && lhsDevice.uuid == rhsDevice.uuid
            case (.resume(device: let lhsDevice), .resume(device: let rhsDevice)): return lhsDevice.uuid == rhsDevice.uuid
            case (.stop(uuid: let lhsUUID), .stop(uuid: let rhsUUID)): return lhsUUID == rhsUUID
            default: return false
            }
        }
        
        case start(session: Session, device: any BluetoothDevice)
        case resume(device: any BluetoothDevice)
        case stop(uuid: AirCasting.SessionUUID)
    }
    
    var callsHistory: [HistoryItem] = []
    
    var mockStorage = MockStorage()
    
    func startRecording(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) { callsHistory.append(.start(session: session, device: device)) }
    func resumeRecording(device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) { callsHistory.append(.resume(device: device)) }
    func stopRecordingSession(with uuid: AirCasting.SessionUUID, databaseChange: (AirCasting.MobileSessionStorage) -> Void) {
        callsHistory.append(.stop(uuid: uuid))
        databaseChange(mockStorage)
    }
    
    class MockStorage: MobileSessionStorage {
        enum HistoryItem {
            case updateSessionStatus(sessionStatus: SessionStatus)
            case updateEndTime
        }
        
        var callsHistory: [HistoryItem] = []
        func updateSessionStatus(_ sessionStatus: AirCasting.SessionStatus, for sessionUUID: AirCasting.SessionUUID) {
            callsHistory.append(.updateSessionStatus(sessionStatus: sessionStatus))
        }
        
        func updateSessionEndtime(_ endTime: Date, for uuid: AirCasting.SessionUUID) {
            callsHistory.append(.updateEndTime)
        }
    }
}
