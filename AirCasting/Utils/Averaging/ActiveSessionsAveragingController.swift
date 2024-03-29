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
    // Two hours: 60 * 60 * 2 = 7200
    case firstThreshold = 7200
    // Nine hours: 60 * 60 * 9 = 32400
    case secondThreshold = 32400
}

final class ActiveSessionsAveragingController: NSObject {
    @Injected var storage: AveragingServiceStorage
    @Injected private var averagingService: MeasurementsAveragingService
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
        
        let fromSessionStartToFirstThreshold = (startTime.timeIntervalSince(DateBuilder.getFakeUTCDate()) + Double(TimeThreshold.firstThreshold.rawValue) + Double(1))
        Log.info("Scheduling periodic averaging start in \(fromSessionStartToFirstThreshold)s for \(session.uuid) [\(session.name ?? "unnamed")]")
        let timer = Timer.publish(every: TimeInterval(fromSessionStartToFirstThreshold), on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.startPeriodicAveraging(uuid: uuid, window: .firstThresholdWindow)
            }
        timers[uuid] = timer
    }
    
    private func startPeriodicAveraging(uuid: SessionUUID, window: AveragingWindow) {
        Log.info("Starting periodic averaging with window of \(window.rawValue)s for \(uuid)")
        let timer = Timer.publish(every: TimeInterval(window.rawValue), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.storage.accessStorage { storage in
                    guard let session = try? storage.getExistingSession(with: uuid) else {
                        Log.info("Couldnt get session with uuid:\(uuid) from db to start periodic averaging")
                        return }
                    Log.info("Periodic averaging fired for \(session.name ?? "N/A")")
                    guard let checkWindow = self.averagingWindowFor(startTime: session.startTime) else {return}
                    let windowDidChange = checkWindow != window
                    if windowDidChange {
                        self.startPeriodicAveraging(uuid: uuid, window: checkWindow)
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

            _ = averagingService.averageMeasurementsWithReminder(
                measurements: measurements,
                startTime: intervalStart,
                averagingWindow: averagingWindow) { averagedMeasurement, sourceMeasurements in
                    guard sourceMeasurements.count > 0 else { return }
                    let lastMeasurementIndex = sourceMeasurements.endIndex-1
                    sourceMeasurements[lastMeasurementIndex].value = averagedMeasurement.value
                    sourceMeasurements[lastMeasurementIndex].time = averagedMeasurement.time
                    sourceMeasurements[lastMeasurementIndex].averagingWindow = averagingWindow.rawValue
                    
                    guard sourceMeasurements.count > 1 else { return }
                    storage.deleteMeasurements(Array(sourceMeasurements[0...lastMeasurementIndex-1]))
                }
        }
    }
    
    private func averagingWindowFor(startTime: Date?) -> AveragingWindow? {
        guard let startTime = startTime else {
            Log.info("Can't calculate averaging window, session doesn't have the startTime")
            return nil
        }
        let sessionDuration = abs(startTime.timeIntervalSince(DateBuilder.getFakeUTCDate()))
        if sessionDuration <= TimeInterval(TimeThreshold.firstThreshold.rawValue) {
            return .zeroWindow
        } else if sessionDuration <= TimeInterval(TimeThreshold.secondThreshold.rawValue) {
            return .firstThresholdWindow
        }
        return .secondThresholdWindow
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
