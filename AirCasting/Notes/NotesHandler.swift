// Created by Lunar on 16/12/2021.
//

import Foundation
import CoreData

protocol NotesHandler: AnyObject {
    func addNote(noteText: String)
    func deleteNote(note: Note)
    func updateNote(note: Note, newText: String, completion: @escaping () -> Void)
    func getNotes(completion: @escaping ([Note]) -> Void)
    func fetchSpecifiedNote(number: Int, completion: @escaping (Note) -> Void)
    var observer: (() -> Void)? { get set }
}

@objc
class NotesHandlerDefault: NSObject, NotesHandler, NSFetchedResultsControllerDelegate {
    var measurementStreamStorage: MeasurementStreamStorage
    var sessionUUID: SessionUUID
    var locationTracker: LocationTracker
    var observer: (() -> Void)?
    private let sessionUpdateService: SessionUpdateService
    private let frc: NSFetchedResultsController<NoteEntity>
    
    init(measurementStreamStorage: MeasurementStreamStorage, sessionUUID: SessionUUID, locationTracker: LocationTracker, sessionUpdateService: SessionUpdateService, persistenceController: PersistenceController) {
        self.measurementStreamStorage = measurementStreamStorage
        self.sessionUUID = sessionUUID
        self.locationTracker = locationTracker
        self.sessionUpdateService = sessionUpdateService
        let fetchRequest = NoteEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "text", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistenceController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        frc.delegate = self
        try? frc.performFetch()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?()
    }
    
    func addNote(noteText: String) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                let currentNumber = try storage.getNotes(for: sessionUUID).map(\.number).sorted(by: < ).last
                try storage.addNote(Note(date: Date().currentUTCTimeZoneDate,
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
    
    func updateNote(note: Note, newText: String, completion: @escaping () -> Void) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateNote(note, newText: newText, for: sessionUUID)
                fetchSession { session in
                    self.sessionUpdateService.updateSession(session: session) {
                        Log.info("Notes successfully updated")
                        completion()
                    }
                }
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

// MARK: Internal methods
extension NotesHandlerDefault {
    private func fetchSession(completion: @escaping (SessionEntity) -> Void) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                completion(try storage.getExistingSession(with: sessionUUID))
            } catch {
                Log.info("Error when deleting note")
            }
        }
    }
}
