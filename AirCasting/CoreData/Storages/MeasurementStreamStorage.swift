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

protocol MeasurementStreamStorageContextUpdate {
    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws
    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws
    func saveMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID
    func createSession(_ session: Session) throws
    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws
    func updateSessionNameAndTags(name: String, tags: String, for sessionUUID: SessionUUID) throws
    func updateSessionFollowing(_ sessionStatus: SessionFollowing, for sessionUUID: SessionUUID)
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID?
    func markSessionForDelete(_ sessionUUID: SessionUUID) throws
    func markStreamForDelete(_ sessionUUID: SessionUUID, sensorsName: [String], completion: () -> Void) throws
    func deleteSession(_ sessionUUID: SessionUUID) throws
    func deleteStreams(_ sessionUUID: SessionUUID) throws
    func addNote(_ note: Note, for sessionUUID: SessionUUID) throws
    func save() throws
}

extension HiddenCoreDataMeasurementStreamStorage {
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D? = nil, toStreamWithID id: MeasurementStreamLocalID, on time: Date = DateBuilder.getRawDate().currentUTCTimeZoneDate) throws {
        try addMeasurement(Measurement(time: time, value: value, location: location), toStreamWithID: id)
    }
}

final class CoreDataMeasurementStreamStorage: MeasurementStreamStorage {

    @Injected private var persistenceController: PersistenceController
    @Injected private var updateSessionParamsService: UpdateSessionParamsService
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

final class HiddenCoreDataMeasurementStreamStorage: MeasurementStreamStorageContextUpdate {
    func markStreamForDelete(_ sessionUUID: SessionUUID, sensorsName: [String], completion: () -> Void) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        try sensorsName.forEach { sensorName in
            guard let stream = sessionEntity.allStreams.first(where: { $0.sensorName == sensorName }) else {
                Log.info("Error when trying to hide measurement streams")
                return
            }
            stream.gotDeleted = true
            try context.save()
            forceUpdate(sessionEntity: sessionEntity)
        }
        completion()
    }

    func markSessionForDelete(_ sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.gotDeleted = true
        try context.save()
    }

    enum Error: Swift.Error {
        case missingMeasurementStream
        case missingSensorName
    }

    @Injected private var updateSessionParamsService: UpdateSessionParamsService
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func deleteSession(_ sessionUUID: SessionUUID) throws {
        do {
            try context.delete(context.existingSession(uuid: sessionUUID))
        } catch {
            Log.error("Error when deleting session")
        }
    }

    func deleteStreams(_ sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        let toDelete = sessionEntity.allStreams.filter({ $0.gotDeleted })
        toDelete.forEach { object in
            context.delete(object)
        }
        forceUpdate(sessionEntity: sessionEntity)
    }

    func forceUpdate(sessionEntity: SessionEntity) {
        sessionEntity.changesCount += 1
        // EXPLANATION for above line:
        // We basically force core data to send change notifications for this Session objects in the app
        // because the NSOrderedSet operations don't trigger KVO and thus don't trigger ObservableObject changes
    }

    func save() throws {
        try self.context.save()
    }

    func removeDuplicatedMeasurements(for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.allStreams.forEach({ stream in
            guard let measurements = stream.allMeasurements else { return }
            let sortedMeasurements = measurements.sorted(by: { $0.time < $1.time })
            for (i, measurement) in sortedMeasurements.enumerated() {
                if i > 0 {
                    if measurement.time.roundedDownToSecond == sortedMeasurements[i-1].time.roundedDownToSecond {
                        context.delete(measurement)
                    }
                }
            }
        })
        Log.info("Deleted duplicated measurements")
    }

    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
        let stream = try context.existingObject(with: id.id) as! MeasurementStreamEntity

        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.time
        newMeasurement.value = measurement.value
        stream.addToMeasurements(newMeasurement)

        let session = stream.session

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

    func saveMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        return try saveMeasurementStream(for: sessionEntity, context: context, stream)
    }

    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        return try saveMeasurementStream(for: sessionEntity, context: context, stream)
    }

    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID? {
        let session = try context.existingSession(uuid: sessionUUID)
        let stream = session.streamWith(sensorName: name)
        return stream?.localID
    }

    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity {
        let session = try context.existingSession(uuid: sessionUUID)
        return session
    }

    func removeAllMeasurements(in stream: MeasurementStreamEntity, except measurementsToLeave: [MeasurementEntity]) {
        let idsToLeave = measurementsToLeave.map(\.objectID)
        let measurementsToDelete = stream.allMeasurements?.filter { !idsToLeave.contains($0.objectID) } ?? []
        measurementsToDelete.forEach { context.delete($0) }
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
    
    func updateSessionEndTimeWithoutUTCConversion(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.endTime = endTime
    }

    func updateSessionNameAndTags(name: String, tags: String, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.name = name
        sessionEntity.tags = tags
        try context.save()
    }
    
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.version = Int16(version)
    }

    func updateSessionFollowing(_ sessionFollowing: SessionFollowing, for sessionUUID: SessionUUID) {
        do {
            let sessionEntity = try context.existingSession(uuid: sessionUUID)
            if sessionFollowing == SessionFollowing.following {
                sessionEntity.followedAt = DateBuilder.getFakeUTCDate()
            } else {
                sessionEntity.followedAt = nil
                if let ui = sessionEntity.userInterface {
                    context.delete(ui)
                }
            }
            try context.save()
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }

    func updateSessionOrder(_ order: Int, for sessionUUID: SessionUUID) {
        do {
            let sessionEntity = try context.existingSession(uuid: sessionUUID)
            sessionEntity.rowOrder = Int64(order)
            try context.save()
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }

    func giveHighestOrder(to sessionUUID: SessionUUID) {
        do {
            let sessionEntity = try context.existingSession(uuid: sessionUUID)
            let highestOrder = try context.getHighestRowOrder()
            sessionEntity.rowOrder = (highestOrder ?? 0) + 1
            try context.save()
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }

    func setOrderToZero(for sessionUUID: SessionUUID) {
        do {
            let sessionEntity = try context.existingSession(uuid: sessionUUID)
            sessionEntity.rowOrder = 0
            try context.save()
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notes

    enum NoteStorageError: Swift.Error, LocalizedError {
        case storageEmpty
        case noteNotFound
        case malformedStorageState
        case multipleNotesFound

        var errorDescription: String? {
            switch self {
            case .storageEmpty: return "Note storage is empty"
            case .multipleNotesFound: return "Multiple notes for given ID found"
            case .noteNotFound: return "No note with given ID found"
            case .malformedStorageState: return "Data storage is in malformed state"
            }
        }
    }

    func addNote(_ note: Note, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        let noteEntity = NoteEntity(context: context)
        noteEntity.lat = note.lat
        noteEntity.long = note.long
        noteEntity.text = note.text
        noteEntity.date = note.date
        noteEntity.number = Int64(note.number)
        sessionEntity.addToNotes(noteEntity)
    }

    func updateNote(_ note: Note, newText: String, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        if let note = (sessionEntity.notes?.first(where: { ($0 as! NoteEntity).number == note.number }) as? NoteEntity) {
            note.text = newText
        }
    }

    func deleteNote(_ note: Note, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        if let note = (sessionEntity.notes?.first(where: { ($0 as! NoteEntity).number == note.number }) as? NoteEntity) {
            context.delete(note)
        }
    }

    func getNotes(for sessionUUID: SessionUUID) throws -> [Note] {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        return sessionEntity.notes?.map { note -> Note in
            let n = note as! NoteEntity
            return Note(date: n.date ?? DateBuilder.getFakeUTCDate(),
                                   text: n.text ?? "",
                                   lat: n.lat,
                                   long: n.long,
                                   number: Int(n.number))
        } ?? []
    }

    func fetchSpecifiedNote(for sessionUUID: SessionUUID, number: Int) throws -> Note {
        let session = try context.existingSession(uuid: sessionUUID)
        guard let allSessionNotes = session.notes else { throw NoteStorageError.storageEmpty }
        let matching = try allSessionNotes.filter {
            guard let note = $0 as? NoteEntity else { throw NoteStorageError.malformedStorageState }
            return note.number == number
        }
        guard matching.count > 0 else { throw NoteStorageError.noteNotFound }
        guard matching.count == 1 else { throw NoteStorageError.multipleNotesFound }
        let note = matching[0] as! NoteEntity

        return Note(date: note.date ?? DateBuilder.getFakeUTCDate(),
                    text: note.text ?? "",
                    lat: note.lat,
                    long: note.long,
                    number: Int(note.number))
    }
    
    private func newSessionEntity() -> SessionEntity {
        let sessionEntity = SessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.session = sessionEntity
        return sessionEntity
    }

    func createSession(_ session: Session) throws {
        let sessionEntity = newSessionEntity()
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