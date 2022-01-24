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
            sessionsData.forEach { session in
                measurementsDownloadingService.downloadMeasurements(for: session.uuid, lastSynced: session.lastSynced) {
                    //TODO: this is probably just temporary. Let's figure out how they do it in android
                    removeDoubledMeasurements(session.uuid)
                }
            }
        }
    }
    
    private func prepareSessionsData(_ sessionsUUIDs: [SessionUUID], completion: @escaping ([(uuid: SessionUUID, lastSynced: Date)]) -> Void) {
        measurementStreamStorage.accessStorage { storage in
            let sessionsData = sessionsUUIDs.map { (uuid: $0, lastSynced: getLastSyncDate(for: $0, storage: storage)) }
            completion(sessionsData)
        }
    }
    
    private func getLastSyncDate(for sessionUUID: SessionUUID, storage: HiddenCoreDataMeasurementStreamStorage) -> Date {
        if let existingSession = try? storage.getExistingSession(with: sessionUUID) {
            if let sessionEndTimeSeconds = existingSession.endTime?.timeIntervalSince1970 {
                let last24hours = DateBuilder.getSince1970using((sessionEndTimeSeconds - measurementTimeframe))
                if let startTime = existingSession.startTime {
                    return startTime < last24hours ? last24hours : startTime
                } else {
                    return last24hours
                }
            } else {
                let last24hours = DateBuilder.getSince1970using((DateBuilder.getSince1970() - measurementTimeframe))
                return last24hours
            }
        } else {
            let last24hours = DateBuilder.getSince1970using((DateBuilder.getSince1970() - measurementTimeframe))
            return last24hours
        }
    }
    
    private func removeDoubledMeasurements(_ sessionUUID: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.removeDuplicatedMeasurements(for: sessionUUID)
            } catch {
                Log.error("Error occured while removing duplicated measurements: \(error)")
            }
        }
    }
}
