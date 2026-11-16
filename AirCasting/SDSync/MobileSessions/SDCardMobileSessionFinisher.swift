// Created by Lunar on 4.06.25.
//

import Foundation
import Resolver
import CoreData


protocol SessionFinisher {
    func callAsFunction(uuid: SessionUUID) throws
}

class SDCardMobileSessionFinisher : SessionFinisher {
    @Injected private var persistenceController: PersistenceController
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    private lazy var context: NSManagedObjectContext = persistenceController.editContext

    func callAsFunction(uuid: SessionUUID) throws {
        // `editContext` is privateQueueConcurrencyType — every read/write must
        // be inside `perform` / `performAndWait`. Earlier callers fired this
        // finisher from `DispatchQueue.global`, so the previous direct-access
        // implementation raced the V2 sync-replay saves on the same context
        // and the `.FINISHED` mutation was frequently lost (session stayed on
        // the mobile-active tab). Also call `save()` explicitly so the change
        // doesn't sit pending until an unrelated `accessStorage` happens to
        // flush it.
        var caughtError: Error?
        context.performAndWait {
            do {
                let sessionEntity = try context.existingSession(uuid: uuid)
                guard sessionEntity.isInStandaloneMode else {
                    Log.info("SD Sync tried finish \(uuid) which is not in standalone mode!")
                    return
                }

                sessionEntity.status = .FINISHED
                // Use a bounded fetch (one indexed row per stream) for the end
                // time. `sessionEntity.lastMeasurementTime` materializes the
                // ENTIRE `measurements` ordered set into an array AND sorts it
                // (MeaurementStreamExtension.latestMeasurementEntity) — for a
                // just-synced full-flash session that faults hundreds of
                // thousands of rows and blocks this `performAndWait` (and the
                // sync dialog at 100%) for tens of seconds.
                if let endTime = latestMeasurementTime(for: sessionEntity) {
                    Log.info("SD Sync measurement end time for session (UUID | name) \(sessionEntity.uuid) \(sessionEntity.name ?? ""): \(endTime)")
                    sessionEntity.endTime = endTime
                }

                if context.hasChanges {
                    try context.save()
                }
            } catch {
                caughtError = error
            }
        }
        if let caughtError { throw caughtError }

        // `activeSession` lingers across the RECORDING→DISCONNECTED flip done
        // by `SessionManagingReconnectionController.didStartReconnecting`
        // (which only mutates DB status — not the in-memory active-session
        // reference). After this finisher writes FINISHED, the post-sync
        // disconnect would otherwise hit `shouldReconnect == true` (the
        // stale `activeSession.device.uuid` still matches) and the
        // auto-reconnect chain would resume recording behind the wizard.
        // Clear the reference here so the chain skips this device.
        if activeSessionProvider.activeSession?.session.uuid == uuid {
            activeSessionProvider.clearActiveSession()
        }
    }

    /// Latest measurement time for the session via a bounded, index-served
    /// fetch: one `time`-DESC `fetchLimit = 1` query per stream (served by the
    /// `(measurementStream, time)` unique index), maxed across streams. Does NOT
    /// materialize or sort the measurements relation. Must be called on
    /// `context`'s queue (this runs inside `callAsFunction`'s `performAndWait`).
    private func latestMeasurementTime(for session: SessionEntity) -> Date? {
        var latest: Date?
        for stream in session.allStreams {
            let request = NSFetchRequest<NSManagedObject>(entityName: "MeasurementEntity")
            request.predicate = NSPredicate(format: "measurementStream == %@", stream)
            request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
            request.fetchLimit = 1
            guard let time = (try? context.fetch(request))?.first?.value(forKey: "time") as? Date else { continue }
            if latest == nil || time > latest! { latest = time }
        }
        return latest
    }
}
