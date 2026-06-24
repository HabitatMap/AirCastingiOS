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
    /// Look up the DISCONNECTED mobile session recorded by the AirBeam with this BLE
    /// peripheral UUID, mapped to a `Session` value. Used on reconnect to rebuild the
    /// in-memory active session after a cold relaunch (the in-memory provider is emptied
    /// on app kill), so the V2 backfill binds and is captured instead of dropped.
    func disconnectedMobileSession(forPeripheralUUID peripheralUUID: String) throws -> Session?
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

    func disconnectedMobileSession(forPeripheralUUID peripheralUUID: String) throws -> Session? {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND status == %li AND bluetoothConnection.peripheralUUID == %@",
                                        SessionType.mobile.rawValue,
                                        SessionStatus.DISCONNECTED.rawValue,
                                        peripheralUUID)
        request.fetchLimit = 1
        guard let entity = try context.fetch(request).first else { return nil }
        return Session(uuid: entity.uuid,
                       type: entity.type,
                       name: entity.name,
                       deviceType: entity.deviceType,
                       location: entity.location,
                       startTime: entity.startTime,
                       locationless: entity.locationless,
                       measurementInterval: entity.measurementInterval)
    }
}
