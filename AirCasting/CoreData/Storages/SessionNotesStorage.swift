// Created by Lunar on 28/11/2022.
//

import Foundation
import Resolver
import CoreData

protocol SessionNotesStorage {
    func accessStorage(_ task: @escaping(HiddenSessionNotesStorage) -> Void)
}

protocol HiddenSessionNotesStorage {
    func save() throws
    func getNotes(for sessionUUID: SessionUUID) throws -> [Note]
    func fetchSpecifiedNote(for sessionUUID: SessionUUID, number: Int) throws -> Note
    func addNote(_ note: Note, for sessionUUID: SessionUUID) throws
    func updateNote(_ note: Note, newText: String, for sessionUUID: SessionUUID) throws
    func deleteNote(_ note: Note, for sessionUUID: SessionUUID) throws
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity
}

class DefaultSessionNotesStorage: SessionNotesStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenSessionNotesStorage = DefaultHiddenSessionNotesStorage(context: self.context)

    /// All actions performed on DefaultSessionNotesStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenSessionNotesStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }}

class DefaultHiddenSessionNotesStorage: HiddenSessionNotesStorage {
    private let context: NSManagedObjectContext

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
}
