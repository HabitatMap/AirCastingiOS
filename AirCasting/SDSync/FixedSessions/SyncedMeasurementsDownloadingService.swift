// Created by Lunar on 14/12/2021.
//

import Foundation

protocol SyncedMeasurementsDownloader {
    func download(sessionsUUIDs: [SessionUUID])
}

struct SyncedMeasurementsDownloadingService: SyncedMeasurementsDownloader {
    private let measurementStreamStorage: MeasurementStreamStorage
    private let measurementsDownloadingService: MeasurementUpdatingService
    let measurementTimeframe: Double = 24 * 60 * 60 // 24 hours in seconds
    
    init(measurementStreamStorage: MeasurementStreamStorage, measurementsDownloadingService: MeasurementUpdatingService) {
        self.measurementStreamStorage = measurementStreamStorage
        self.measurementsDownloadingService = measurementsDownloadingService
    }
    
    func download(sessionsUUIDs: [SessionUUID]) {
        
        prepareSessionsData(sessionsUUIDs) { sessionsData in
            sessionsData.forEach { measurementsDownloadingService.updateMeasurements(for: $0.uuid, lastSynced: $0.lastSynced) }
        }
    }
    
    private func prepareSessionsData(_ sessionsUUIDs: [SessionUUID], completion: @escaping ([(uuid: SessionUUID, lastSynced: Date)]) -> Void) {
        measurementStreamStorage.accessStorage { storage in
            let sessionsData = sessionsUUIDs.map { (uuid: $0, lastSynced: getLastSyncDate(for: $0, storage: storage)) }
            Log.info("## \(sessionsData)")
            completion(sessionsData)
        }
    }
    
    private func getLastSyncDate(for sessionUUID: SessionUUID, storage: HiddenCoreDataMeasurementStreamStorage) -> Date {
        if let existingSession = try? storage.getExistingSession(with: sessionUUID) {
            if let sessionEndTimeSeconds = existingSession.endTime?.timeIntervalSince1970 {
                let last24hours = Date(timeIntervalSince1970: (sessionEndTimeSeconds - measurementTimeframe))
                if let startTime = existingSession.startTime {
                    return startTime < last24hours ? last24hours : startTime
                } else {
                    return last24hours
                }
            } else {
                let last24hours = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 - measurementTimeframe))
                return last24hours
            }
        } else {
            let last24hours = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 - measurementTimeframe))
            return last24hours
        }
    }
}
