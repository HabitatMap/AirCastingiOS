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
    /// Batched variant — one fetch covering the full timestamp range,
    /// then a two-pointer sweep. Use for sync replay paths where the
    /// per-record `nearest(...)` cost (one fetch per record) dominates.
    /// Returns one element per input timestamp in the same order; nil
    /// where no sample fell inside tolerance.
    func nearestBatch(sessionUUID: SessionUUID,
                      timestamps: [Date],
                      tolerance: TimeInterval) -> [LocationSample?]
    /// For each input timestamp, the most recent sample at or before it —
    /// the "last known location" (sample-and-hold / carry-forward). Returns
    /// one element per input timestamp in the same order; nil only when no
    /// sample exists at or before that timestamp (e.g. a record taken before
    /// the session's first fix). Used to fill backfilled records that fell
    /// outside every sample's tolerance window so the measurement keeps a
    /// coordinate (the dot holds at the last good point) instead of being
    /// dropped from the map/CSV.
    func latestSampleAtOrBefore(sessionUUID: SessionUUID,
                                timestamps: [Date]) -> [LocationSample?]
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

    func nearestBatch(sessionUUID: SessionUUID,
                      timestamps: [Date],
                      tolerance: TimeInterval) -> [LocationSample?] {
        guard !timestamps.isEmpty else { return [] }
        var results: [LocationSample?] = Array(repeating: nil, count: timestamps.count)
        var hits = 0
        var sampleCount = 0
        context.performAndWait { [context] in
            let minTs = timestamps.min()!
            let maxTs = timestamps.max()!
            let lower = minTs.addingTimeInterval(-tolerance)
            let upper = maxTs.addingTimeInterval(tolerance)
            let request = NSFetchRequest<NSManagedObject>(entityName: "LocationSampleEntity")
            request.predicate = NSPredicate(
                format: "sessionUUID == %@ AND timestamp >= %@ AND timestamp <= %@",
                sessionUUID.rawValue, lower as NSDate, upper as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            do {
                let rows = try context.fetch(request)
                guard !rows.isEmpty else { return }
                let samples: [(Date, Double, Double)] = rows.compactMap { row in
                    guard let ts = row.value(forKey: "timestamp") as? Date,
                          let lat = row.value(forKey: "latitude") as? Double,
                          let lon = row.value(forKey: "longitude") as? Double else { return nil }
                    return (ts, lat, lon)
                }
                guard !samples.isEmpty else { return }
                sampleCount = samples.count

                // Sort timestamps by value to enable two-pointer sweep;
                // emit each result back into its original input slot.
                let indexed = timestamps.enumerated().sorted { $0.element < $1.element }
                var cursor = 0
                for (originalIndex, target) in indexed {
                    while cursor + 1 < samples.count,
                          abs(samples[cursor + 1].0.timeIntervalSince(target)) <
                          abs(samples[cursor].0.timeIntervalSince(target)) {
                        cursor += 1
                    }
                    let candidate = samples[cursor]
                    if abs(candidate.0.timeIntervalSince(target)) <= tolerance {
                        results[originalIndex] = LocationSample(
                            sessionUUID: sessionUUID,
                            timestamp: candidate.0,
                            latitude: candidate.1,
                            longitude: candidate.2
                        )
                        hits += 1
                    }
                }
            } catch {
                Log.error("V2LocationBackfill.Store: nearestBatch fetch failed: \(error)")
            }
        }
        Log.info("V2LocationBackfill.Store: nearestBatch \(sessionUUID) n=\(timestamps.count) samples=\(sampleCount) tol=\(tolerance) hits=\(hits)")
        return results
    }

    func latestSampleAtOrBefore(sessionUUID: SessionUUID,
                                timestamps: [Date]) -> [LocationSample?] {
        guard !timestamps.isEmpty else { return [] }
        var results: [LocationSample?] = Array(repeating: nil, count: timestamps.count)
        var hits = 0
        var sampleCount = 0
        context.performAndWait { [context] in
            guard let maxTs = timestamps.max() else { return }
            // Only samples at or before the latest target can be "last known"
            // for any of these timestamps.
            let request = NSFetchRequest<NSManagedObject>(entityName: "LocationSampleEntity")
            request.predicate = NSPredicate(
                format: "sessionUUID == %@ AND timestamp <= %@",
                sessionUUID.rawValue, maxTs as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            do {
                let rows = try context.fetch(request)
                guard !rows.isEmpty else { return }
                let samples: [(Date, Double, Double)] = rows.compactMap { row in
                    guard let ts = row.value(forKey: "timestamp") as? Date,
                          let lat = row.value(forKey: "latitude") as? Double,
                          let lon = row.value(forKey: "longitude") as? Double else { return nil }
                    return (ts, lat, lon)
                }
                guard !samples.isEmpty else { return }
                sampleCount = samples.count

                // Process targets in ascending order with a monotonic cursor:
                // for each target, advance to the latest sample whose timestamp
                // is <= target. cursor == -1 means no sample precedes this
                // target (record taken before the first fix) → leave nil.
                let indexed = timestamps.enumerated().sorted { $0.element < $1.element }
                var cursor = -1
                for (originalIndex, target) in indexed {
                    while cursor + 1 < samples.count, samples[cursor + 1].0 <= target {
                        cursor += 1
                    }
                    guard cursor >= 0 else { continue }
                    let s = samples[cursor]
                    results[originalIndex] = LocationSample(sessionUUID: sessionUUID,
                                                            timestamp: s.0,
                                                            latitude: s.1,
                                                            longitude: s.2)
                    hits += 1
                }
            } catch {
                Log.error("V2LocationBackfill.Store: latestSampleAtOrBefore fetch failed: \(error)")
            }
        }
        Log.info("V2LocationBackfill.Store: latestSampleAtOrBefore \(sessionUUID) n=\(timestamps.count) samples=\(sampleCount) heldHits=\(hits)")
        return results
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
