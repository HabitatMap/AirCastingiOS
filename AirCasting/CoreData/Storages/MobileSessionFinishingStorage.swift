// Created by Lunar on 18/11/2022.
//

import Foundation
import Resolver
import CoreData

protocol MobileSessionFinishingStorage {
    func accessStorage(_ task: @escaping(HiddenMobileSessionFinishingStorage) -> Void)
}

protocol HiddenMobileSessionFinishingStorage {
    func save() throws
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws
}

class DefaultMobileSessionFinishingStorage: MobileSessionFinishingStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenMobileSessionFinishingStorage = DefaultHiddenMobileSessionFinishingStorage(context: self.context)

    /// All actions performed on HiddenMobileSessionFinishingStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenMobileSessionFinishingStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            do {
                try self.hiddenStorage.save()
            } catch {
                Log.error("[FINISH] Initial save failed: \(error). Sweeping orphans and retrying.")
                // Orphan MeasurementEntity rows (nil `time` or nil
                // `measurementStream`) can pile up in editContext from
                // interrupted SD sync / recording flows. Child-context save
                // runs attribute-required validation and throws on those
                // orphans — the previous `try?` swallowed it, so the user's
                // "Finish recording" tap silently failed and the session was
                // stuck at DISCONNECTED. Sweep + retry instead.
                self.deleteOrphanedMeasurements()
                do {
                    try self.hiddenStorage.save()
                } catch {
                    Log.error("[FINISH] Save still failing after orphan sweep: \(error)")
                }
            }
        }
    }

    private func deleteOrphanedMeasurements() {
        let request = MeasurementEntity.fetchRequest()
        request.predicate = NSPredicate(format: "time == nil OR measurementStream == nil")
        do {
            let orphans = try context.fetch(request)
            guard !orphans.isEmpty else { return }
            Log.warning("[FINISH] Removing \(orphans.count) orphaned MeasurementEntity row(s) before retry")
            orphans.forEach(context.delete(_:))
        } catch {
            Log.error("[FINISH] Orphan sweep failed: \(error)")
        }
    }
}

class DefaultHiddenMobileSessionFinishingStorage: HiddenMobileSessionFinishingStorage {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func save() throws {
        guard context.hasChanges else { return }
        try self.context.save()
    }

    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = sessionStatus
    }

    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.endTime = endTime.currentUTCTimeZoneDate
    }
}
