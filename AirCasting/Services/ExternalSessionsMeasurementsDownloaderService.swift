//// Created by Lunar on 11/05/2022.
////
//
//import Foundation
//
//struct ExternalSessionsMeasurementsDownloaderService {
//    func updateAllExternalSessionsMeasurements() {
//        getAllSessionsData() { [unowned self] sessionsData in
//            Log.info("Scheduled measurements update triggered (session count: \(sessionsData.count))")
//            sessionsData.forEach { self.updateMeasurements(for: $0.uuid, lastSynced: $0.lastSynced) }
//        }
//    }
//    
//    private func getAllSessionsData(completion: @escaping ([(uuid: SessionUUID, lastSynced: Date)]) -> Void) {
//        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
//        request.predicate = NSPredicate(format: "followedAt != NULL")
//        let context = persistenceController.editContext
//        var returnData: [(uuid: SessionUUID, lastSynced: Date)] = []
//        context.perform { [unowned self] in
//            do {
//                let sessions = try context.fetch(request)
//                returnData = sessions.map { ($0.uuid, self.getSyncDate(for: $0)) }
//                completion(returnData)
//            } catch {
//                Log.error("Error fetching sessions data: \(error)")
//            }
//        }
//    }
//    
//    private func getSyncDate(for session: SessionEntity?) -> Date {
//        let lastMeasurementTime = session?.allStreams?
//            .compactMap(\.lastMeasurementTime)
//            .sorted()
//            .last
//        let syncDate = SyncHelper().calculateLastSync(sessionEndTime: session?.endTime, lastMeasurementTime: lastMeasurementTime)
//        return syncDate
//    }
//}
