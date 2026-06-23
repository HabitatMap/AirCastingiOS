// Created by Lunar on 29/09/2021.
//

import Foundation
import Combine
import Resolver
import CoreData

/**
  * Averaging for long mobile sessions
  *
  * General rules:
  * - for streams containing >2 hrs but <9 hrs of data apply a 5-second avg. time interval.
  * - for streams containing >9 hrs of data apply a 60-second avg. time interval
  *
  * Use case:
  * - the mobile active session reaches a duration of 2 hours and 5 seconds.
  * - at 2 hours and 5 seconds, the first 5-second average measurement is plotted on the map and graph.
 * - all of the data from the prior 2 hours is transformed into 5-second averages and the map and graph and stats are updated accordingly.
 *
 * Notes:
 * - averages should be attached to the middle value geocoordinates, and timestamp should be set to the interval end
 * i.e. if its a 5-second avg spanning the time frame 10:00:00 to 10:00:05,
 * the avg value gets pegged to the geocoordinates of middle measurement and timestamp from 10:00:05.
 * - thresholds are calculated based on ellapsed time of session, not based on actual measurements records
 * (pauses in sessions are not taken into account)
 *
 **/

struct AvgMeasurement {
    let window: AveragingWindow = .zeroWindow
    let treshold: TimeThreshold
}

enum AveragingWindow: Int {
    case zeroWindow = 1
    case firstThresholdWindow = 5
    case secondThresholdWindow = 60
}

enum TimeThreshold: Int {
    // ⚠️⚠️⚠️ TEST ONLY — DO NOT MERGE. REVERT BEFORE SHIPPING. ⚠️⚠️⚠️
    // Compressed thresholds so averaging engages within ~1 min instead of
    // 2 h / 9 h, to exercise the averaging-during-active-sync path in a short
    // force-quit repro. With these values: <30 s no averaging, 30–60 s → 5 s
    // window, >60 s → 60 s window (same window the failed >9 h session used).
    // PRODUCTION VALUES: firstThreshold = 7200 (2 h), secondThreshold = 32400 (9 h).
    case firstThreshold = 30
    case secondThreshold = 60
}

final class ActiveSessionsAveragingController: NSObject {
    @Injected var storage: AveragingServiceStorage
    @Injected private var averagingService: MeasurementsAveragingService
    @Injected private var persistenceController: PersistenceController
    private var timers: [SessionUUID : AnyCancellable] = [:]
    private var fetchedResultsController: NSFetchedResultsController<SessionEntity>?
    
    func start() {
        storage.accessStorage { storage in
            let frc = storage.observerForMobileSessions()
            
            do {
                try frc.performFetch()
            } catch {
                Log.info("Couldn't perform a fetch and add observer")
            }
            frc.delegate = self
            self.fetchedResultsController = frc
            Log.info("Averaging service started")
        }
    }
    
    private func scheduleAveraging(session: SessionEntity) {
        let uuid = session.uuid
        guard let startTime = session.startTime else { return }

        // Sparse-interval gate: if the user picked a native interval ≥ the 60s second
        // window (the coarsest averaging bucket), every bucket would hold ≤ 1 sample
        // and the leftover-sweep in `perform(...)` would wipe the only row in the
        // window. Skip scheduling entirely. Android parity: commit `c4cdd9b9a`.
        let nativeInterval = session.nativeMeasurementIntervalSeconds
        guard nativeInterval < AveragingWindow.secondThresholdWindow.rawValue else {
            Log.info("Skipping periodic averaging schedule for \(session.uuid): native interval \(nativeInterval)s ≥ 60s")
            return
        }

        // First-window pick: if the native interval ≥ 5s, the 5s window is also too
        // coarse — fast-forward straight to the 60s window (still scheduled at the
        // 2h threshold so the FRC delegate doesn't have to re-pick later).
        let initialWindow: AveragingWindow = nativeInterval < AveragingWindow.firstThresholdWindow.rawValue
            ? .firstThresholdWindow
            : .secondThresholdWindow

        let fromSessionStartToFirstThreshold = (startTime.timeIntervalSince(DateBuilder.getFakeUTCDate()) + Double(TimeThreshold.firstThreshold.rawValue) + Double(1))
        Log.info("Scheduling periodic averaging start in \(fromSessionStartToFirstThreshold)s for \(session.uuid) [\(session.name ?? "unnamed")] firstWindow=\(initialWindow.rawValue)s nativeInterval=\(nativeInterval)s")
        let timer = Timer.publish(every: TimeInterval(fromSessionStartToFirstThreshold), on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.startPeriodicAveraging(uuid: uuid, window: initialWindow)
            }
        timers[uuid] = timer
    }
    
    private func startPeriodicAveraging(uuid: SessionUUID, window: AveragingWindow) {
        // ⚠️ TEST ONLY — DO NOT MERGE. Fire every 1s (not every window.rawValue s) so
        // multiple averaging passes land DURING an active sync even for a SHORT disconnect
        // (no need to record an hour) — exercises the interleaved multi-pass path against a
        // still-arriving (reverse-order) buffer. perform() still averages with the 60s window
        // via checkWindow, so output stays 1-min.
        // PRODUCTION: Timer.publish(every: TimeInterval(window.rawValue), on: .main, in: .common)
        Log.info("Starting periodic averaging with window of \(window.rawValue)s (TEST tick=1s) for \(uuid)")
        let timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.storage.accessStorage { storage in
                    guard let session = try? storage.getExistingSession(with: uuid) else {
                        Log.info("Couldnt get session with uuid:\(uuid) from db to start periodic averaging")
                        return }
                    Log.info("Periodic averaging fired for \(session.name ?? "N/A")")
                    guard let checkWindow = self.averagingWindowFor(startTime: session.startTime,
                                                                    nativeInterval: session.nativeMeasurementIntervalSeconds) else {return}
                    let windowDidChange = checkWindow != window
                    if windowDidChange {
                        self.startPeriodicAveraging(uuid: uuid, window: checkWindow)
                    }
                    // Suppress periodic averaging while a V2 sync burst is back-filling:
                    // the reverse-order replay arrives mid-window, so averaging a
                    // half-arrived window then re-averaging the rest collides on the
                    // (measurementStream,time) unique constraint (PM1/PM2.5 desync +
                    // wrong value). One clean pass runs at drain via averageSessionNow().
                    guard !self.persistenceController.isSyncBurstActive else {
                        Log.info("Periodic averaging skipped for \(uuid) — V2 sync burst active")
                        return
                    }
                    self.perform(storage: storage,
                                 session: session,
                                 averagingWindow: checkWindow)
                    Log.info("Averaging performed for \(session.uuid) [\(session.name ?? "N/A")]")
                }
            }
        timers[uuid] = timer
    }
    
    private func perform(storage: HiddenAveragingServiceStorage, session: SessionEntity, averagingWindow: AveragingWindow) {
        Log.info("Performing averaging for \(session.uuid) [\(session.name ?? "unnamed")]")
        session.allStreams.forEach { stream in
            guard let measurements = try? storage.fetchUnaveragedMeasurements(currentWindow: averagingWindow, stream: stream) else { return }

            guard let intervalStart = stream.session?.startTime else { Log.error("No session start time!"); return }

            // DIAGNOSTIC (test): count what each averaging pass does to the rows.
            // Identity check: fetched == emitted + deleted + reminderKept. If that
            // holds yet rows still vanish from the chart, the loss is at the store
            // save (unique (stream,time) constraint dedup of rewritten survivors),
            // not in the algorithm. Remove with the threshold revert.
            var emitted = 0
            var deleted = 0
            let reminder = averagingService.averageMeasurementsWithReminder(
                measurements: measurements,
                startTime: intervalStart,
                averagingWindow: averagingWindow) { averagedMeasurement, sourceMeasurements in
                    guard sourceMeasurements.count > 0 else { return }
                    let lastMeasurementIndex = sourceMeasurements.endIndex-1
                    sourceMeasurements[lastMeasurementIndex].value = averagedMeasurement.value
                    sourceMeasurements[lastMeasurementIndex].time = averagedMeasurement.time
                    sourceMeasurements[lastMeasurementIndex].averagingWindow = averagingWindow.rawValue
                    emitted += 1

                    guard sourceMeasurements.count > 1 else { return }
                    deleted += sourceMeasurements.count - 1
                    storage.deleteMeasurements(Array(sourceMeasurements[0...lastMeasurementIndex-1]))
                }
            Log.warning("[V2SYNC] avg stream=\(stream.sensorName ?? "?") window=\(averagingWindow.rawValue)s fetched=\(measurements.count) emitted=\(emitted) deleted=\(deleted) reminderKept=\(reminder.count)")
        }
    }

    /// Run a single averaging pass for a session immediately, bypassing the
    /// sync-burst gate. Called at V2 active-sync drain (after every back-filled
    /// row has arrived) so the whole backlog is averaged in one clean pass —
    /// every window is full → no partial re-average, no (measurementStream,time)
    /// constraint collision. `completion` fires after the editContext save lands.
    func averageSessionNow(uuid: SessionUUID, completion: @escaping () -> Void) {
        storage.accessStorage { [weak self] storage in
            defer { completion() }
            guard let self = self else { return }
            guard let session = try? storage.getExistingSession(with: uuid),
                  let window = self.averagingWindowFor(startTime: session.startTime,
                                                       nativeInterval: session.nativeMeasurementIntervalSeconds)
            else {
                Log.info("averageSessionNow: no session/window for \(uuid), skipping")
                return
            }
            Log.info("averageSessionNow: post-sync averaging pass for \(uuid) window=\(window.rawValue)s")
            self.perform(storage: storage, session: session, averagingWindow: window)
            try? storage.save()
        }
    }

    private func averagingWindowFor(startTime: Date?, nativeInterval: Int) -> AveragingWindow? {
        guard let startTime = startTime else {
            Log.info("Can't calculate averaging window, session doesn't have the startTime")
            return nil
        }
        let sessionDuration = abs(startTime.timeIntervalSince(DateBuilder.getFakeUTCDate()))
        if sessionDuration <= TimeInterval(TimeThreshold.firstThreshold.rawValue) {
            return .zeroWindow
        } else if sessionDuration <= TimeInterval(TimeThreshold.secondThreshold.rawValue) {
            // 5s-native sessions can't be averaged at the 5s window (≤ 1 sample per
            // bucket → leftover-sweep wipes the row); fall back to zero/passthrough
            // until the duration crosses into the 60s-window range.
            return nativeInterval < AveragingWindow.firstThresholdWindow.rawValue ? .firstThresholdWindow : .zeroWindow
        }
        // 60s+ native sessions also can't be averaged at the 60s window — keep them
        // at the passthrough zero window. (scheduleAveraging short-circuits before
        // we ever get here for ≥ 60s native, but the gate stays for safety.)
        return nativeInterval < AveragingWindow.secondThresholdWindow.rawValue ? .secondThresholdWindow : .zeroWindow
    }
}

extension ActiveSessionsAveragingController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let session = anObject as? SessionEntity else { return }
        
        switch type {
        case .insert:
            scheduleAveraging(session: session)
        case .delete:
            timers[session.uuid] = nil
        default: break
        }
    }
    
}
