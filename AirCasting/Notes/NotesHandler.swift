// Created by Lunar on 16/12/2021.
//

import Foundation

protocol NotesHandler {
    func addNoteToDatabase(note: Note)
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
                Log.info("Error when deleting sessions/streams")
            }
        }
    }
    
    func getNotesFromDatabase() -> [Note] {
        var notes = [Note]()
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                notes = try storage.getNotes(for: session.uuid)
            } catch {
                Log.info("Error when fetching notes from DB")
            }
        }
        return notes
    }
}
