// Created by Lunar on 09/05/2021.
//

import CoreData
import CoreLocation
import Foundation
import Combine

protocol MeasurementStreamStorage {
    func accessStorage(_ task: @escaping(HiddenCoreDataMeasurementStreamStorage) -> Void)
}

protocol MeasurementStreamStorageContextUpdate {
    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws
    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws
    func createMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID
    func createSession(_ session: Session) throws
    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws
    func updateSessionFollowing(_ sessionStatus: SessionFollowing, for sessionUUID: SessionUUID)
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID?
    func save() throws
}

extension HiddenCoreDataMeasurementStreamStorage {
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D? = nil, toStreamWithID id: MeasurementStreamLocalID, on time: Date = Date().currentUTCTimeZoneDate) throws {
        try addMeasurement(Measurement(time: time, value: value, location: location), toStreamWithID: id)
    }
}

final class CoreDataMeasurementStreamStorage: MeasurementStreamStorage {

    private let persistenceController: PersistenceController
    private lazy var updateSessionParamsService = UpdateSessionParamsService()
    private let context: NSManagedObjectContext
    let hiddenStorage: HiddenCoreDataMeasurementStreamStorage
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.context = persistenceController.editContext
        self.hiddenStorage = HiddenCoreDataMeasurementStreamStorage(context: self.context)
    }
    
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

final class HiddenCoreDataMeasurementStreamStorage: MeasurementStreamStorageContextUpdate {

    enum Error: Swift.Error {
        case missingMeasurementStream
        case missingSensorName
    }
    
    private lazy var updateSessionParamsService = UpdateSessionParamsService()
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func save() throws {
        try self.context.save()
    }

    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
        let stream = try context.existingObject(with: id.id) as! MeasurementStreamEntity

        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.time
        newMeasurement.value = measurement.value
        stream.addToMeasurements(newMeasurement)

        let session = stream.session
//        session?.endTime = newMeasurement.time
        // This line is going to be disabled as soon as someone says it's important ⁉️
        // because it is not crashing our timeZone
        
        //otherwise dormant session status changes to active when syncing measurements
        if session?.status != .FINISHED {
            session?.status = .RECORDING
        }
    }
    
    func addMeasurements(_ measurements: [Measurement], toStreamWithID id: MeasurementStreamLocalID) throws {
        let stream = try context.existingObject(with: id.id) as! MeasurementStreamEntity

        measurements.forEach { measurement in
            let newMeasurement = MeasurementEntity(context: context)
            newMeasurement.location = measurement.location
            newMeasurement.time = measurement.time
            newMeasurement.value = measurement.value
            stream.addToMeasurements(newMeasurement)
        }
        
        Log.info("## Added measurements to stream \(stream): \(stream.measurements)")
    }
    
    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws {
        let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: sensorName)
        if existingThreshold == nil {
            let threshold: SensorThreshold = try context.newOrExisting(sensorName: sensorName)
            threshold.thresholdVeryLow = thresholdVeryLow
            threshold.thresholdLow = thresholdLow
            threshold.thresholdMedium = thresholdMedium
            threshold.thresholdHigh = thresholdHigh
            threshold.thresholdVeryHigh = thresholdVeryHigh
        }
    }

    func createMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        Log.info("## Created measurement stream for \(sessionEntity.name)")
        return try createMeasurementStream(for: sessionEntity, context: context, stream)
    }

    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
        let sessionEntity = SessionEntity(context: context)
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        return try createMeasurementStream(for: sessionEntity, context: context, stream)
    }
    
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID? {
        let session = try context.existingSession(uuid: sessionUUID)
        let stream = session.streamWith(sensorName: name)
        return stream?.localID
    }
    
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity? {
        let session = try context.existingSession(uuid: sessionUUID)
        return session
    }
    
    func updateMeasurements(stream: MeasurementStreamEntity, newMeasurements: NSOrderedSet) throws {
            stream.measurements = newMeasurements
    }
    
    private func createMeasurementStream(for session: SessionEntity, context: NSManagedObjectContext, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
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
        // Save here is important so that NSManagedObjectID is not temporary.
        try context.save()
        
        try context.obtainPermanentIDs(for: [newStream])

        return newStream.localID
    }
    
    func setStatusToFinishedAndUpdateEndTime(for sessionUUID: SessionUUID, endTime: Date?) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = .FINISHED
        guard endTime != nil else { return }
        sessionEntity.endTime = endTime
    }

    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = sessionStatus
        try context.save()
    }
    
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.endTime = endTime.currentUTCTimeZoneDate

        try context.save()
    }
    
    func updateSessionFollowing(_ sessionFollowing: SessionFollowing, for sessionUUID: SessionUUID) {
        do {
            let sessionEntity = try context.existingSession(uuid: sessionUUID)
            if sessionFollowing == SessionFollowing.following {
                sessionEntity.followedAt = Date().currentUTCTimeZoneDate
            } else {
                sessionEntity.followedAt = nil
            }
            try context.save()
        } catch {
            Log.info("Error when saving changes in session: \(error.localizedDescription) ")
        }
    }

    func createSession(_ session: Session) throws {
        let sessionEntity = SessionEntity(context: context)
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        try context.save()
    }
    
    func observerFor<T>(request: NSFetchRequest<T>) -> NSFetchedResultsController<T> {
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }
}

#if DEBUG
/// Only to be used for swiftui previews
final class PreviewMeasurementStreamStorage: MeasurementStreamStorage {
    func accessStorage(_ task: @escaping (HiddenCoreDataMeasurementStreamStorage) -> Void) {
        print("accessing storage")
    }
    
    func save() throws {
        print("Faking saving ")
    }
    
    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws {
        print("Faking saving thresholds")
    }
    
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        print("Faking updating sessioon end time happened: \(endTime) for session \(sessionUUID)")
    }
    
    func updateSessionFollowing(_ sessionStatus: SessionFollowing, for sessionUUID: SessionUUID) {}
    
    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
        print("Nothing happened for \(measurement)")
    }

    func createMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        fatalError()
    }

    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
        fatalError()
    }
    
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID? {
        fatalError()
    }

    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        print("Nothing happened for \(sessionStatus) \(sessionUUID)")
    }

    func createSession(_ session: Session) throws {
        print("Nothing happened for \(session)")
    }
}
#endif
