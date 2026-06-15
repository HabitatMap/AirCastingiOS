// V2 disconnect-window location backfill.
//
// CoreData-backed persistence for buffered location samples. Survives app
// termination so the V2 sync save path can still match measurements to
// per-second/per-interval phone fixes captured while the AirBeam was
// disconnected.

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
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.createContext()

    func insert(_ sample: LocationSample) {
        context.perform { [context] in
            let entity = LocationSampleEntity(context: context)
            entity.sessionUUID = sample.sessionUUID.rawValue
            entity.timestamp = sample.timestamp
            entity.latitude = sample.latitude
            entity.longitude = sample.longitude
            do {
                try context.save()
            } catch {
                Log.error("LocationSampleStore insert failed: \(error)")
            }
        }
    }

    func nearest(sessionUUID: SessionUUID, timestamp: Date, tolerance: TimeInterval) -> LocationSample? {
        var result: LocationSample?
        context.performAndWait { [context] in
            let request: NSFetchRequest<LocationSampleEntity> = LocationSampleEntity.fetchRequest()
            let lower = timestamp.addingTimeInterval(-tolerance)
            let upper = timestamp.addingTimeInterval(tolerance)
            request.predicate = NSPredicate(
                format: "sessionUUID == %@ AND timestamp >= %@ AND timestamp <= %@",
                sessionUUID.rawValue, lower as NSDate, upper as NSDate
            )
            do {
                let rows = try context.fetch(request)
                let best = rows.compactMap { row -> (LocationSampleEntity, Date)? in
                    guard let ts = row.timestamp else { return nil }
                    return (row, ts)
                }.min { lhs, rhs in
                    abs(lhs.1.timeIntervalSince(timestamp)) <
                    abs(rhs.1.timeIntervalSince(timestamp))
                }
                guard let (entity, ts) = best else { return }
                result = LocationSample(
                    sessionUUID: sessionUUID,
                    timestamp: ts,
                    latitude: entity.latitude,
                    longitude: entity.longitude
                )
            } catch {
                Log.error("LocationSampleStore nearest fetch failed: \(error)")
            }
        }
        return result
    }

    func deleteAll(sessionUUID: SessionUUID) {
        context.perform { [context] in
            let request: NSFetchRequest<LocationSampleEntity> = LocationSampleEntity.fetchRequest()
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
            let request: NSFetchRequest<LocationSampleEntity> = LocationSampleEntity.fetchRequest()
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
