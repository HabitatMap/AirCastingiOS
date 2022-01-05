// Created by Lunar on 16/12/2021.
//

import Foundation

protocol NotesHandler {
    func addNoteToDatabase(note: Note)
    func markWithNumberID() -> Int
    func deleteNoteFromDatabase(note: Note)
    func updateNoteInDatabase(note: Note, newText: String)
    func getNotesFromDatabase(completion: @escaping ([Note]) -> Void)
    func fetchSpecifiedNote(number: Int, completion: @escaping (Note) -> Void)
}

class NotesHandlerDefault: NotesHandler {
    var measurementStreamStorage: MeasurementStreamStorage
    var sessionUUID: SessionUUID
    var sessionNotesNumber: Int
    
    init(measurementStreamStorage: MeasurementStreamStorage, sessionUUID: SessionUUID, sessionNotesNumber: Int = 0) {
        self.measurementStreamStorage = measurementStreamStorage
        self.sessionUUID = sessionUUID
        self.sessionNotesNumber = sessionNotesNumber
    }
    
    func addNoteToDatabase(note: Note) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.addNote(note, for: sessionUUID)
            } catch {
                Log.info("Error when adding to DB")
            }
        }
    }
    
    func deleteNoteFromDatabase(note: Note) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.deleteNote(note, for: sessionUUID)
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
    
    func updateNoteInDatabase(note: Note, newText: String) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateNote(note, newText: newText, for: sessionUUID)
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
    
    func markWithNumberID() -> Int { sessionNotesNumber }
    
    func getNotesFromDatabase(completion: @escaping ([Note]) -> Void) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                completion(try storage.getNotes(for: sessionUUID))
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
    
    func fetchSpecifiedNote(number: Int, completion: @escaping (Note) -> Void) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                completion(try storage.fetchSpecifiedNote(for: sessionUUID, number: number))
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
}
