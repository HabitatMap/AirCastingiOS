// Created by Lunar on 09/05/2021.
//

import CoreData
import CoreLocation
import Foundation
import Combine
import SwiftUI
import Resolver

protocol MeasurementStreamStorage {
    func accessStorage(_ task: @escaping(HiddenCoreDataMeasurementStreamStorage) -> Void)
}

extension HiddenCoreDataMeasurementStreamStorage {
//    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D? = nil, toStreamWithID id: MeasurementStreamLocalID, on time: Date = DateBuilder.getRawDate().currentUTCTimeZoneDate) throws {
//        try addMeasurement(Measurement(time: time, value: value, location: location), toStreamWithID: id)
//    }
}

final class CoreDataMeasurementStreamStorage: MeasurementStreamStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage = HiddenCoreDataMeasurementStreamStorage(context: self.context)

    /// All actions performed on CoreDataMeasurementStreamStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenCoreDataMeasurementStreamStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

final class HiddenCoreDataMeasurementStreamStorage {
    enum Error: Swift.Error {
        case missingMeasurementStream
        case missingSensorName
    }

    @Injected private var updateSessionParamsService: UpdateSessionParamsService
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func save() throws {
        try self.context.save()
    }

//    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
//        let stream = try context.existingObject(with: id.id) as! MeasurementStreamEntity
//
//        let newMeasurement = MeasurementEntity(context: context)
//        newMeasurement.location = measurement.location
//        newMeasurement.time = measurement.time
//        newMeasurement.value = measurement.value
//        stream.addToMeasurements(newMeasurement)
//
//        let session = stream.session
//
//        // otherwise dormant session status changes to active when syncing measurements
//        if session?.status != .FINISHED {
//            session?.status = .RECORDING
//        }
//    }

//    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws {
//        let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: sensorName)
//        if existingThreshold == nil {
//            let threshold: SensorThreshold = try context.newOrExisting(sensorName: sensorName)
//            threshold.thresholdVeryLow = thresholdVeryLow
//            threshold.thresholdLow = thresholdLow
//            threshold.thresholdMedium = thresholdMedium
//            threshold.thresholdHigh = thresholdHigh
//            threshold.thresholdVeryHigh = thresholdVeryHigh
//        }
//    }

    func saveMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        return try saveMeasurementStream(for: sessionEntity, context: context, stream)
    }

    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        _ = try saveMeasurementStream(for: sessionEntity, context: context, stream)
    }

//    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID? {
//        let session = try context.existingSession(uuid: sessionUUID)
//        let stream = session.streamWith(sensorName: name)
//        return stream?.localID
//    }

    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity {
        let session = try context.existingSession(uuid: sessionUUID)
        return session
    }

    private func saveMeasurementStream(for session: SessionEntity, context: NSManagedObjectContext, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
        let newStream = MeasurementStreamEntity(context: context)
        newStream.sensorName = stream.sensorName
        newStream.sensorPackageName = stream.sensorPackageName
        newStream.measurementType = stream.measurementType
        newStream.measurementShortType = stream.measurementShortType
        newStream.unitName = stream.unitName
        newStream.unitSymbol = stream.unitSymbol
        newStream.thresholdVeryLow = stream.thresholdVeryLow
        newStream.thresholdLow = stream.thresholdLow
        newStream.thresholdMedium = stream.thresholdMedium
        newStream.thresholdHigh = stream.thresholdHigh
        newStream.thresholdVeryHigh = stream.thresholdVeryHigh
        newStream.gotDeleted = false

        session.addToMeasurementStreams(newStream)

        guard let sensorName = stream.sensorName else {
            throw Error.missingSensorName
        }

        let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: sensorName)
        if existingThreshold == nil {
            let threshold: SensorThreshold = try context.newOrExisting(sensorName: sensorName)
            threshold.thresholdVeryLow = stream.thresholdVeryLow
            threshold.thresholdLow = stream.thresholdLow
            threshold.thresholdMedium = stream.thresholdMedium
            threshold.thresholdHigh = stream.thresholdHigh
            threshold.thresholdVeryHigh = stream.thresholdVeryHigh
        }

        return newStream.localID
    }

//    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
//        let sessionEntity = try context.existingSession(uuid: sessionUUID)
//        sessionEntity.status = sessionStatus
//        try context.save()
//    }

//    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws {
//        let sessionEntity = try context.existingSession(uuid: sessionUUID)
//        sessionEntity.endTime = endTime.currentUTCTimeZoneDate
//
//        try context.save()
//    }
    
//    func updateSessionEndTimeWithoutUTCConversion(_ endTime: Date, for sessionUUID: SessionUUID) throws {
//        let sessionEntity = try context.existingSession(uuid: sessionUUID)
//        sessionEntity.endTime = endTime
//    }

//    func updateSessionNameAndTags(name: String, tags: String, for sessionUUID: SessionUUID) throws {
//        let sessionEntity = try context.existingSession(uuid: sessionUUID)
//        sessionEntity.name = name
//        sessionEntity.tags = tags
//        try context.save()
//    }
    
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.version = Int16(version)
    }

//    func updateSessionFollowing(_ sessionFollowing: SessionFollowing, for sessionUUID: SessionUUID) {
//        do {
//            let sessionEntity = try context.existingSession(uuid: sessionUUID)
//            if sessionFollowing == SessionFollowing.following {
//                sessionEntity.followedAt = DateBuilder.getFakeUTCDate()
//            } else {
//                sessionEntity.followedAt = nil
//                if let ui = sessionEntity.userInterface {
//                    context.delete(ui)
//                }
//            }
//            try context.save()
//        } catch {
//            Log.error("Error when saving changes in session: \(error.localizedDescription)")
//        }
//    }
    
    private func newSessionEntity() -> SessionEntity {
        let sessionEntity = SessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.session = sessionEntity
        return sessionEntity
    }
    
    // MARK: - Create Session
    
    @discardableResult
    func createSession(_ session: Session) throws -> SessionEntity {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        try context.save()
        return sessionEntity
    }
}

#if DEBUG
/// Only to be used for swiftui previews
final class PreviewMeasurementStreamStorage: MeasurementStreamStorage {
    func accessStorage(_ task: @escaping (HiddenCoreDataMeasurementStreamStorage) -> Void) {
        Log.info("accessing storage")
    }

    func save() throws {
        Log.info("Faking saving ")
    }

    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws {
        Log.info("Faking saving thresholds")
    }

    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        Log.info("Faking updating sessioon end time happened: \(endTime) for session \(sessionUUID)")
    }

    func updateSessionFollowing(_ sessionStatus: SessionFollowing, for sessionUUID: SessionUUID) {}

    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
        Log.info("Nothing happened for \(measurement)")
    }

    func saveMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        fatalError()
    }

    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
        fatalError()
    }

    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID? {
        fatalError()
    }

    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        Log.info("Nothing happened for \(sessionStatus) \(sessionUUID)")
    }

    func createSession(_ session: Session) throws {
        Log.info("Nothing happened for \(session)")
    }
}
#endif
