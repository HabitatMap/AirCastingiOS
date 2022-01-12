// Created by Lunar on 16/12/2021.
//

import Foundation

protocol NotesHandler {
    func addNote(noteText: String)
    func deleteNote(note: Note)
    func updateNote(note: Note, newText: String)
    func getNotes(completion: @escaping ([Note]) -> Void)
    func fetchSpecifiedNote(number: Int, completion: @escaping (Note) -> Void)
}

class NotesHandlerDefault: NotesHandler {
    var measurementStreamStorage: MeasurementStreamStorage
    var sessionUUID: SessionUUID
    var locationTracker: LocationTracker
    
    init(measurementStreamStorage: MeasurementStreamStorage, sessionUUID: SessionUUID, locationTracker: LocationTracker) {
        self.measurementStreamStorage = measurementStreamStorage
        self.sessionUUID = sessionUUID
        self.locationTracker = locationTracker
    }
    
    func addNote(noteText: String) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                let currentNumber = try storage.getNotes(for: sessionUUID).map(\.number).sorted(by: < ).last
                try storage.addNote(Note(date: Date(),
                                         text: noteText,
                                         lat: locationTracker.googleLocation.last?.location.latitude ?? 20.0,
                                         long: locationTracker.googleLocation.last?.location.longitude ?? 20.0,
                                         number: (currentNumber ?? -1) + 1),
                                    for: sessionUUID)
            } catch {
                Log.info("Error when adding to DB")
            }
        }
    }
    
    func deleteNote(note: Note) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.deleteNote(note, for: sessionUUID)
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
    
    func updateNote(note: Note, newText: String) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateNote(note, newText: newText, for: sessionUUID)
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
    
    func getNotes(completion: @escaping ([Note]) -> Void) {
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
