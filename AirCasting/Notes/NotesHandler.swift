// Created by Lunar on 16/12/2021.
//

import Foundation

protocol NotesHandler {
    func addNoteToDatabase(note: Note)
    func getNotesFromDatabase() -> [Note]
    func obtainNumber() -> Int
    func fetchSpecifiedNote(number: Int) -> Note
    func deleteNoteFromDatabase(note: Note)
    func updateNoteInDatabase(note: Note, newText: String)
}

class NotesHandlerDefault: NotesHandler {
    var measurementStreamStorage: MeasurementStreamStorage
    var session: SessionEntity
    
    init(measurementStreamStorage: MeasurementStreamStorage, session: SessionEntity) {
        self.measurementStreamStorage = measurementStreamStorage
        self.session = session
    }
    
    func addNoteToDatabase(note: Note) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.addNote(note, for: session.uuid)
            } catch {
                Log.info("Error when adding to DB")
            }
        }
    }
    
    func deleteNoteFromDatabase(note: Note) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.deleteNote(note, for: session.uuid)
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
    
    func updateNoteInDatabase(note: Note, newText: String) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateNote(note, newText: newText, for: session.uuid)
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
    
    func obtainNumber() -> Int { session.notes?.count ?? 0 }
    
// WHAT BELOW SHOULDN"T BE HERE - USING NoteEntity HERE BAAAAD ‼️
    func getNotesFromDatabase() -> [Note] {
        var notesArray = [Note]()
        session.notes?.forEach({ note in
            let n = note as! NoteEntity
            notesArray.append(Note(date: n.date ?? Date(),
                                   text: n.text ?? "",
                                   lat: n.lat,
                                   long: n.long,
                                   number: Int(n.number)))
        })
        return notesArray
    }
    
    func fetchSpecifiedNote(number: Int) -> Note {
        let note = (session.notes?.first(where: { ($0 as! NoteEntity).number == number }) as! NoteEntity)
        return Note(date: note.date ?? Date(),
                    text: note.text ?? "",
                    lat: note.lat,
                    long: note.long,
                    number: Int(note.number))
    }
}
