// Created by Lunar on 14/12/2021.
//

import Foundation
import Resolver

protocol SyncedMeasurementsDownloader {
    func download(sessionsUUIDs: [SessionUUID])
}

struct SyncedMeasurementsDownloadingService: SyncedMeasurementsDownloader {
    @Injected private var measurementStreamStorage: SDSyncMeasurementsStorage
    @Injected private var measurementsDownloadingService: MeasurementUpdatingService
    let measurementTimeframe: Double = 24 * 60 * 60 // 24 hours in seconds

    func download(sessionsUUIDs: [SessionUUID]) {
        prepareSessionsData(sessionsUUIDs) { sessionsData in
            sessionsData.forEach { session in
                measurementsDownloadingService.downloadMeasurements(for: session.uuid, lastSynced: session.lastSynced) {
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

    private func getLastSyncDate(for sessionUUID: SessionUUID, storage: HiddenSDSyncMeasurementsStorage) -> Date {
        if let existingSession = try? storage.getExistingSession(with: sessionUUID) {
            if let sessionEndTimeSeconds = existingSession.endTime?.timeIntervalSince1970 {
                let last24hours = DateBuilder.getDateWithTimeIntervalSince1970((sessionEndTimeSeconds - measurementTimeframe))
                if let startTime = existingSession.startTime {
                    return startTime < last24hours ? last24hours : startTime
                } else {
                    return last24hours
                }
            } else {
                let last24hours = DateBuilder.getDateWithTimeIntervalSince1970((DateBuilder.getTimeIntervalSince1970() - measurementTimeframe))
                return last24hours
            }
        } else {
            let last24hours = DateBuilder.getDateWithTimeIntervalSince1970((DateBuilder.getTimeIntervalSince1970() - measurementTimeframe))
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
