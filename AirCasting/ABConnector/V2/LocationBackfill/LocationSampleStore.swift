// V2 disconnect-window location backfill.
//
// CoreData-backed persistence for buffered location samples. Uses its own
// dedicated NSPersistentContainer (`LocationSampleStoreContainer`) so
// inserts hit disk on every save, independent of
// `PersistenceController.uiSuspended`. The shared `sourceOfTruthContext`
// only flushes to disk while the app is foreground; long backgrounded
// sessions used to leave thousands of in-memory samples that vanished if
// iOS jetsamed the process before the user reopened the app.

import Foundation
import CoreData
import CoreLocation
import Resolver

protocol LocationSampleStore {
    func insert(_ sample: LocationSample)
    func nearest(sessionUUID: SessionUUID, timestamp: Date, tolerance: TimeInterval) -> LocationSample?
    func deleteAll(sessionUUID: SessionUUID)
    func deleteOrphans(activeSessionUUIDs: Set<SessionUUID>)
}

final class DefaultLocationSampleStore: LocationSampleStore {
    private lazy var context: NSManagedObjectContext = {
        let ctx = LocationSampleStoreContainer.shared.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        ctx.name = "locationSampleStore"
        return ctx
    }()

    func insert(_ sample: LocationSample) {
        context.perform { [context] in
            let entity = NSEntityDescription.insertNewObject(
                forEntityName: "LocationSampleEntity",
                into: context
            )
            entity.setValue(sample.sessionUUID.rawValue, forKey: "sessionUUID")
            entity.setValue(sample.timestamp, forKey: "timestamp")
            entity.setValue(sample.latitude, forKey: "latitude")
            entity.setValue(sample.longitude, forKey: "longitude")
            do {
                try context.save()
                Log.info("V2LocationBackfill.Store: inserted sample for \(sample.sessionUUID) ts=\(sample.timestamp.timeIntervalSince1970) lat=\(sample.latitude) lon=\(sample.longitude)")
            } catch {
                Log.error("V2LocationBackfill.Store: insert failed: \(error)")
            }
        }
    }

    func nearest(sessionUUID: SessionUUID, timestamp: Date, tolerance: TimeInterval) -> LocationSample? {
        var result: LocationSample?
        var debugRowCount = 0
        var debugTotalForSession = 0
        context.performAndWait { [context] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "LocationSampleEntity")
            let lower = timestamp.addingTimeInterval(-tolerance)
            let upper = timestamp.addingTimeInterval(tolerance)
            request.predicate = NSPredicate(
                format: "sessionUUID == %@ AND timestamp >= %@ AND timestamp <= %@",
                sessionUUID.rawValue, lower as NSDate, upper as NSDate
            )
            do {
                let rows = try context.fetch(request)
                debugRowCount = rows.count
                let best = rows.compactMap { row -> (NSManagedObject, Date)? in
                    guard let ts = row.value(forKey: "timestamp") as? Date else { return nil }
                    return (row, ts)
                }.min { lhs, rhs in
                    abs(lhs.1.timeIntervalSince(timestamp)) <
                    abs(rhs.1.timeIntervalSince(timestamp))
                }
                if let (entity, ts) = best {
                    result = LocationSample(
                        sessionUUID: sessionUUID,
                        timestamp: ts,
                        latitude: entity.value(forKey: "latitude") as? Double ?? 0,
                        longitude: entity.value(forKey: "longitude") as? Double ?? 0
                    )
                }
                if result == nil {
                    let allReq = NSFetchRequest<NSManagedObject>(entityName: "LocationSampleEntity")
                    allReq.predicate = NSPredicate(format: "sessionUUID == %@", sessionUUID.rawValue)
                    debugTotalForSession = (try? context.count(for: allReq)) ?? -1
                }
            } catch {
                Log.error("V2LocationBackfill.Store: nearest fetch failed: \(error)")
            }
        }
        if let r = result {
            Log.info("V2LocationBackfill.Store: lookup HIT \(sessionUUID) target=\(timestamp.timeIntervalSince1970) tol=\(tolerance) → ts=\(r.timestamp.timeIntervalSince1970) Δ=\(r.timestamp.timeIntervalSince(timestamp))s lat=\(r.latitude) lon=\(r.longitude) (\(debugRowCount) in window)")
        } else {
            Log.warning("V2LocationBackfill.Store: lookup MISS \(sessionUUID) target=\(timestamp.timeIntervalSince1970) tol=\(tolerance) — 0 in window, \(debugTotalForSession) total samples for session")
        }
        return result
    }

    func deleteAll(sessionUUID: SessionUUID) {
        context.perform { [context] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "LocationSampleEntity")
            request.predicate = NSPredicate(format: "sessionUUID == %@", sessionUUID.rawValue)
            do {
                let rows = try context.fetch(request)
                rows.forEach(context.delete)
                try context.save()
            } catch {
                Log.error("LocationSampleStore deleteAll failed: \(error)")
            }
        }
    }

    func deleteOrphans(activeSessionUUIDs: Set<SessionUUID>) {
        context.perform { [context] in
            let request = NSFetchRequest<NSManagedObject>(entityName: "LocationSampleEntity")
            if !activeSessionUUIDs.isEmpty {
                let raws = activeSessionUUIDs.map(\.rawValue)
                request.predicate = NSPredicate(format: "NOT (sessionUUID IN %@)", raws)
            }
            do {
                let rows = try context.fetch(request)
                rows.forEach(context.delete)
                try context.save()
            } catch {
                Log.error("LocationSampleStore deleteOrphans failed: \(error)")
            }
        }
    }
}
