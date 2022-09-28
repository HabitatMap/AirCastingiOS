// Created by Lunar on 29/09/2021.
//

import Foundation
import Combine
import CoreData
import Algorithms

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
 * - averages should be attached to the middle value geocoordinates and timestamps,
 * i.e. if its a 5-second avg spanning the time frame 10:00:00 to 10:00:05,
 * the avg value gets pegged to the geocoordinates and timestamp from 10:00:03.
 * - thresholds are calculated based on ellapsed time of session, not based on actual measurements records
 * (pauses in sessions are not taken into account)
 * - if there are any final, unaveraged measurements on 2h+ or 9h+ session which would not fall into full averaging window
 * (5s or 60s) they should be deleted
 * - on threshold crossing (at 2h and at 9h into session) we also trim measurements that not fit into given window size
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
    case firstThreshold = 120 //TODO: change back
    // Nine hours: 60 * 60 * 9 = 32400
    case secondThreshold = 32400
}

final class AveragingService: NSObject {
    
    private var sessionEntity: SessionEntity?
    private let measurementStreamStorage: MeasurementStreamStorage
    private var timers: [SessionUUID : AnyCancellable] = [:]
    private var fetchedResultsController: NSFetchedResultsController<SessionEntity>?
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
        super.init()
    }
    
    func start() {
        measurementStreamStorage.accessStorage { [weak self] storage in
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@ AND status == %i",
                                            SessionType.mobile.rawValue,
                                            SessionStatus.RECORDING.rawValue)
            request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: true)]
            
            let frc = storage.observerFor(request: request)
            
            do {
                try frc.performFetch()
            } catch {
                Log.info("Couldn't perform a fetch and add observer")
            }
            frc.delegate = self
            self?.fetchedResultsController = frc
            Log.info("Averaging service started")
        }
    }
    
    func averageMeasurements(for sessions: [SessionUUID], completion: @escaping () -> Void) {
        self.measurementStreamStorage.accessStorage { storage in
            sessions.forEach { uuid in
                guard let session = try? storage.getExistingSession(with: uuid) else {
                    Log.info("Couldnt get session with uuid:\(uuid) from db to perform averaging")
                    return }
                guard let checkWindow = self.averagingWindowFor(startTime: session.startTime) else { return }
                guard checkWindow != .zeroWindow else { return }
                
                self.perform(storage: storage,
                             session: session,
                             averagingWindow: checkWindow,
                             windowDidChange: false)
            }
            completion()
        }
    }
    
    private func perform(storage: HiddenCoreDataMeasurementStreamStorage, session: SessionEntity, averagingWindow: AveragingWindow, windowDidChange: Bool) {
        Log.info("Performing averaging for \(session.uuid ?? "N/A") [\(session.name ?? "unnamed")]")
        session.allStreams.forEach { stream in
            var averagedMeasurements: [MeasurementEntity] = (stream.allMeasurements ?? []).filter {
                $0.averagingWindow == averagingWindow.rawValue
            }
            
            /// Step 1 - it'll be performed only once, after crossing the secondThresholdWindow
            /// The measurements that were already averaged with firstThresholdWindow will be reaveraged with secondThresholdWindow
            if windowDidChange && averagingWindow == .secondThresholdWindow {
                Log.info("Averaging for second threshold window")
                let averagedWithFirstThreshold = (stream.allMeasurements ?? []).filter {
                    $0.averagingWindow == AveragingWindow.firstThresholdWindow.rawValue
                }
                
                let chunkElementsCount = AveragingWindow.secondThresholdWindow.rawValue / AveragingWindow.firstThresholdWindow.rawValue
                averagedWithFirstThreshold.chunks(ofCount: chunkElementsCount).forEach { measuremensInChunk in
                    guard measuremensInChunk.count == chunkElementsCount else { return }
                    let averaged = self.averagedMeasurementFrom(chunk: measuremensInChunk, window: averagingWindow, measurementCount: chunkElementsCount)
                    averagedMeasurements.append(contentsOf: averaged)
                }
            }
            
            /// Step 2 - perform averaging on measurements that haven't been averaged
            let unaveragedMeasurements: [MeasurementEntity] = (stream.allMeasurements ?? []).filter {
                $0.averagingWindow == AveragingWindow.zeroWindow.rawValue
            }

            unaveragedMeasurements.chunks(ofCount: averagingWindow.rawValue).forEach( { measuremensInChunk in
                let averaged = self.averagedMeasurementFrom(chunk: measuremensInChunk, window: averagingWindow, measurementCount: averagingWindow.rawValue)
                averagedMeasurements.append(contentsOf: averaged)
            })
            
            /// Step 3 - Update stream
            if !averagedMeasurements.isEmpty {
                storage.removeAllMeasurements(in: stream, except: averagedMeasurements)
            } else {
                Log.info("There were no averaged mesurements")
            }
        }
    }
    
    private func calculateAvg(from values: ChunksOfCountCollection<[MeasurementEntity]>.Element) -> Double {
       return values.map({ $0.value }).reduce(0.0, +) / Double(values.count)
    }
    
    private func averagedMeasurementFrom(chunk: ArraySlice<MeasurementEntity>, window: AveragingWindow, measurementCount: Int) -> [MeasurementEntity] {
        guard chunk.count == measurementCount else { return Array(chunk) }
        /// https://github.com/apple/swift-algorithms/blob/main/Guides/Chunked.md
        /// For integer types, any remainder of the division is discarded so we need to add 1 to elementsInChunk/2 to get the middle value.
        let middleIndex = chunk.middleItemIndex
        let middleMeasurement = chunk[middleIndex]
        middleMeasurement.value = calculateAvg(from: chunk)
        middleMeasurement.averagingWindow = window.rawValue
        return [middleMeasurement]
    }
    
    private func scheduleAveraging(session: SessionEntity) {
        let uuid = session.uuid
        guard let startTime = session.startTime else { return }
        
        let fromSessionStartToFirstThreshold = (startTime.timeIntervalSince(DateBuilder.getFakeUTCDate()) + Double(TimeThreshold.firstThreshold.rawValue) + Double(1))
        Log.info("Scheduling periodic averaging start in \(fromSessionStartToFirstThreshold)s for \(session.uuid ?? "N/A") [\(session.name ?? "unnamed")]")
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
                self.measurementStreamStorage.accessStorage { storage in
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
                                 averagingWindow: checkWindow,
                                 windowDidChange: windowDidChange)
                    Log.info("Averaging performed for \(session.uuid) [\(session.name)]")
                }
            }
        timers[uuid] = timer
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

extension AveragingService: NSFetchedResultsControllerDelegate {
    
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
