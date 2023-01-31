import Foundation
import Resolver
import CoreData
import CoreLocation

protocol TestMeasurementStreamStorage {
    func accessStorage(_ task: @escaping(HiddenTestMeasurementStreamStorage) -> Void)
}

protocol HiddenTestMeasurementStreamStorage {
    func save() throws
    func getNotes(for sessionUUID: SessionUUID) throws -> [Note]
    func fetchSpecifiedNote(for sessionUUID: SessionUUID, number: Int) throws -> Note
    func addNote(_ note: Note, for sessionUUID: SessionUUID) throws
    func updateNote(_ note: Note, newText: String, for sessionUUID: SessionUUID) throws
    func deleteNote(_ note: Note, for sessionUUID: SessionUUID) throws
    func markSessionForDelete(_ sessionUUID: SessionUUID) throws
    func markStreamForDelete(_ sessionUUID: SessionUUID, sensorsName: [String], completion: () -> Void) throws
    func deleteStreams(_ sessionUUID: SessionUUID) throws
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws
    func removeDuplicatedMeasurements(for sessionUUID: SessionUUID) throws
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws
    func createSession(_ session: Session) throws -> SessionEntity
    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws
    func saveMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID
    
    func existingMeasurementStreamLocalID(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID?
    
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D?, toStreamWithID id: MeasurementStreamLocalID, on time: Date) throws
    func updateSessionFollowing(_ sessionFollowing: SessionFollowing, for sessionUUID: SessionUUID)
    func updateSessionNameAndTags(name: String, tags: String, for sessionUUID: SessionUUID) throws
    func updateSessionEndTimeWithoutUTCConversion(_ endTime: Date, for sessionUUID: SessionUUID) throws
    
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamEntity?
    
    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D?, toStream stream: MeasurementStreamEntity, on time: Date) throws
    
    func observerForMobileSessions() -> NSFetchedResultsController<SessionEntity>
    func fetchUnaveragedMeasurements(currentWindow: AveragingWindow, stream: MeasurementStreamEntity) throws -> [MeasurementEntity]
    func deleteMeasurements(_ measurements: [MeasurementEntity])
}

class DefaultTestMeasurementStreamStorage: TestMeasurementStreamStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenTestMeasurementStreamStorage = DefaultHiddenTestMeasurementStreamStorage(context: self.context)

    /// All actions performed on DefaultSessionNotesStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenTestMeasurementStreamStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

class DefaultHiddenTestMeasurementStreamStorage: HiddenTestMeasurementStreamStorage {
    private let context: NSManagedObjectContext
    @Injected private var updateSessionParamsService: UpdateSessionParamsService

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
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
    
    func save() throws {
        guard context.hasChanges else { return }
        try self.context.save()
    }
    
    func getNotes(for sessionUUID: SessionUUID) throws -> [Note] {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        return sessionEntity.notes?.map { note -> Note in
            let n = note as! NoteEntity
            return Note(date: n.date ?? DateBuilder.getFakeUTCDate(),
                        text: n.text ?? "",
                        lat: n.lat,
                        long: n.long,
                        photoLocation: n.photoLocation,
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
                    photoLocation: note.photoLocation,
                    number: Int(note.number))
    }

    func addNote(_ note: Note, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        let noteEntity = NoteEntity(context: context)
        noteEntity.lat = note.lat
        noteEntity.long = note.long
        noteEntity.text = note.text
        noteEntity.date = note.date
        noteEntity.number = Int64(note.number)
        noteEntity.photoLocation = note.photoLocation
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
    
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.version = Int16(version)
    }
    
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity {
        let session = try context.existingSession(uuid: sessionUUID)
        return session
    }
    
    func markSessionForDelete(_ sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.gotDeleted = true
    }
    
    func markStreamForDelete(_ sessionUUID: SessionUUID, sensorsName: [String], completion: () -> Void) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sensorsName.forEach { sensorName in
            guard let stream = sessionEntity.allStreams.first(where: { $0.sensorName == sensorName }) else {
                Log.info("Error when trying to hide measurement streams")
                return
            }
            stream.gotDeleted = true
            forceUpdate(sessionEntity: sessionEntity)
        }
        completion()
    }
    
    func deleteStreams(_ sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        let toDelete = sessionEntity.allStreams.filter({ $0.gotDeleted })
        toDelete.forEach { object in
            context.delete(object)
        }
        forceUpdate(sessionEntity: sessionEntity)
    }
    
    private func forceUpdate(sessionEntity: SessionEntity) {
        sessionEntity.changesCount += 1
        // EXPLANATION for above line:
        // We basically force core data to send change notifications for this Session objects in the app
        // because the NSOrderedSet operations don't trigger KVO and thus don't trigger ObservableObject changes
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
    
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = sessionStatus
    }
    
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.endTime = endTime.currentUTCTimeZoneDate
    }
    
    @discardableResult
    func createSession(_ session: Session) throws -> SessionEntity {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        return sessionEntity
    }
    
    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        _ = try saveMeasurementStream(for: sessionEntity, context: context, stream)
    }
    
    func existingMeasurementStreamLocalID(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID? {
        let session = try context.existingSession(uuid: sessionUUID)
        let stream = session.streamWith(sensorName: name)
        return stream?.localID
    }
    
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D? = nil, toStreamWithID id: MeasurementStreamLocalID, on time: Date = DateBuilder.getRawDate().currentUTCTimeZoneDate) throws {
        try addMeasurement(Measurement(time: time, value: value, location: location), toStreamWithID: id)
    }
    
    func saveMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        return try saveMeasurementStream(for: sessionEntity, context: context, stream)
    }
    
    private func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
        let stream = try context.existingObject(with: id.id) as! MeasurementStreamEntity

        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.time
        newMeasurement.value = measurement.value
        stream.addToMeasurements(newMeasurement)
    }
    
    private func newSessionEntity() -> SessionEntity {
        let sessionEntity = SessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.session = sessionEntity
        return sessionEntity
    }
    
    enum Error: Swift.Error {
        case missingSensorName
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
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }
    
    func createSession(_ session: Session) throws {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
    }
    
    func updateSessionNameAndTags(name: String, tags: String, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.name = name
        sessionEntity.tags = tags
    }
    
    func updateSessionEndTimeWithoutUTCConversion(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.endTime = endTime
    }
    
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamEntity? {
        let session = try context.existingSession(uuid: sessionUUID)
        let stream = session.streamWith(sensorName: name)
        return stream
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
    
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D? = .undefined, toStream stream: MeasurementStreamEntity, on time: Date) throws {
        try addMeasurement(Measurement(time: time, value: value, location: location), toStream: stream)
    }
    
    private func addMeasurement(_ measurement: Measurement, toStream stream: MeasurementStreamEntity) throws {
        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.time
        newMeasurement.value = measurement.value
        stream.addToMeasurements(newMeasurement)
    }
    
    func observerForMobileSessions() -> NSFetchedResultsController<SessionEntity> {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND status == %i",
                                        SessionType.mobile.rawValue,
                                        SessionStatus.RECORDING.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }
    
    func fetchUnaveragedMeasurements(currentWindow: AveragingWindow, stream: MeasurementStreamEntity) throws -> [MeasurementEntity] {
        let fetchRequest = fetchRequestForUnaveragedMeasurements(currentWindow: currentWindow, stream: stream)
        return try context.fetch(fetchRequest)
    }
    
    func deleteMeasurements(_ measurements: [MeasurementEntity]) {
        measurements.forEach(context.delete(_:))
    }
    
    private func fetchRequestForUnaveragedMeasurements(currentWindow: AveragingWindow, stream: MeasurementStreamEntity) -> NSFetchRequest<MeasurementEntity> {
        let fetchRequest = MeasurementEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "averagingWindow != %d AND measurementStream == %@", currentWindow.rawValue, stream)
        return fetchRequest
    }
}
