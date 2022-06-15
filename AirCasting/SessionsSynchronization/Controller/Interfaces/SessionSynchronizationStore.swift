// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine
import CoreLocation

enum SessionSynchronizationStoreError: Error {
    case noSessionsForUUID(uuid: SessionUUID)
}

/// Defines interface for objects which provide local store for sessions sync
///
/// Overview of the sync process:
/// 1. Fetch sessions stored locally on a device
/// 2. Diff them against global database
/// 3. Download/Upload/Delete accordingly
protocol SessionSynchronizationStore {
    func getLocalSessionList() -> AnyPublisher<[SessionsSynchronization.Metadata], Error>
    
    @discardableResult
    func addSessions(with: [SessionsSynchronization.SessionStoreSessionData]) -> Future<Void, Error>
    
    @discardableResult
    func saveURLForSession(uuid: SessionUUID, url: String) -> Future<Void, Error>
    
    @discardableResult
    func removeSessions(with: [SessionUUID]) -> Future<Void, Error>
    
    func readSession(with: SessionUUID) -> Future<SessionsSynchronization.SessionStoreSessionData, Error>
}

// MARK: Data structures

extension SessionsSynchronization {
    struct Metadata: Equatable, Encodable {
        let uuid: SessionUUID
        let deleted: Bool
        let version: Int?
    }
    
    struct SessionStoreSessionData: Equatable {
        let uuid: SessionUUID
        let contribute: Bool
        let endTime: Date?
        let gotDeleted: Bool
        let isIndoor: Bool
        let name: String
        let startTime: Date
        let tags: String?
        let urlLocation: String?
        let version: Int?
        let longitude: Double?
        let latitude: Double?
        let sessionType: String
        let measurementStreams: [SessionStoreMeasurementStreamData]
        let deleted: Bool
        let notes: [SessionStoreNotesData]
        let notesPhotos: [Data?]
    }
    
    struct SessionStoreMeasurementStreamData: Equatable {
        let id: MeasurementStreamID
        let measurementShortType: String
        let measurementType: String
        let sensorName: SensorName
        let sensorPackageName: String
        let thresholdHigh: Int
        let thresholdLow: Int
        let thresholdMedium: Int
        let thresholdVeryHigh: Int
        let thresholdVeryLow: Int
        let unitName: String
        let unitSymbol: String
        let deleted: Bool
        let measurements: [SessionStoreMeasurementData]
    }
    
    struct SessionStoreMeasurementData: Equatable {
        let id: MeasurementID
        let time: Date
        let value: Double
        let latitude: Double?
        let longitude: Double?
    }
    
    struct SessionStoreNotesData: Equatable {
        let date: Date
        let text: String
        let latitude: Double
        let longitude: Double
        let number: Int
    }
}
