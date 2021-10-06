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

//TODO:
// 5. get proper averaging window (for threshold)

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

final class AveragingService: NSObject, ObservableObject {
    // TODO:
    // 1. calculate average
    // 2. remove unaveraged measurements
    // 3. mark measurements as averaged
    // 4. setup timer for new session
    // 5. perform averaging of previous measurements after crossing threshold
    // 5. get proper averaging window (for threshold)
    
    private var sessionEntity: SessionEntity?
    private let measurementStreamStorage: MeasurementStreamStorage
    private var timers: [SessionUUID : AnyCancellable] = [:]
    private var fetchedResultsController: NSFetchedResultsController<SessionEntity>?
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
        super.init()
        
        measurementStreamStorage.accessStorage { [weak self] storage in
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@ AND status == %i",
                                            SessionType.mobile.rawValue,
                                            SessionStatus.RECORDING.rawValue)
            request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: true)]
            
            let frc = storage.observerFor(request: request)
            
            try! frc.performFetch()
            frc.delegate = self
            self?.fetchedResultsController = frc
        }
    }
    
    private func perform(sessionEntity: SessionEntity, averagingWindow: AveragingWindow) {
        if let uuid = sessionEntity.uuid {
            measurementStreamStorage.accessStorage { storage in
                
                let session = try? storage.getExistingSessionWith(uuid)
                
                session?.allStreams?.forEach { stream in
                    var averagedMeasurements: [MeasurementEntity] = (stream.allMeasurements ?? []).filter {
                        $0.averagingWindow != AveragingWindow.zeroWindow.rawValue
                    }
                    let unaveragedMeasurements: [MeasurementEntity] = (stream.allMeasurements ?? []).filter {
                        $0.averagingWindow == AveragingWindow.zeroWindow.rawValue
                    }
                    
                    unaveragedMeasurements.chunks(ofCount: averagingWindow.rawValue).forEach( { measuremensInChunk in
                        if (measuremensInChunk.count == averagingWindow.rawValue) {
                            /// https://github.com/apple/swift-algorithms/blob/main/Guides/Chunked.md
                            /// For integer types, any remainder of the division is discarded so we need to add 1 to elementsInChunk/2 to get the middle value.
                            let middleIndex = measuremensInChunk.index(measuremensInChunk.startIndex, offsetBy: (averagingWindow.rawValue/2 + 1))
                            let middleMeasurement = measuremensInChunk[middleIndex]
                            middleMeasurement.value = self.calculateAvg(from: measuremensInChunk)
                            middleMeasurement.averagingWindow = averagingWindow.rawValue
                            averagedMeasurements.append(middleMeasurement)
                        }
                    })
                    do {
                        if !averagedMeasurements.isEmpty {
                            try storage.updateMeasurements(stream: stream, newMeasurements: NSOrderedSet(array: averagedMeasurements))
                        }
                    } catch {
                        Log.info("Couldn't update Measurements for stream \(stream)")
                    }
                }
            }
        }
    }
    
    private func calculateAvg(from values: ChunksOfCountCollection<[MeasurementEntity]>.Element) -> Double {
       return values.map({ $0.value }).reduce(0.0, +) / Double(values.count)
    }
    
    private func scheduleAveraging(session: SessionEntity) {
        let uuid = session.uuid!
        
        let timer = Timer.publish(every: TimeInterval(TimeThreshold.firstThreshold.rawValue), on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.measurementStreamStorage.accessStorage { storage in
                    guard let session = try? storage.getExistingSessionWith(uuid) else { return }
                    self?.startPeriodicAveraging(session: session)
                }
            }
        timers[uuid] = timer
    }
    
    private func startPeriodicAveraging(session: SessionEntity) {
        guard let context = session.managedObjectContext,
              let uuid = session.uuid else { return }

        let timer = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                context.perform {
                    guard let session = try? context.existingSession(uuid: uuid) else { return }
                    self?.perform(sessionEntity: session, averagingWindow: .firstThresholdWindow)
                }
            }
        timers[session.uuid] = timer
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
