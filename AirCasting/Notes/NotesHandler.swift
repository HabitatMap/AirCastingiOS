// Created by Lunar on 16/12/2021.
//

import Foundation
import Resolver
import CoreData

protocol NotesHandler: AnyObject {
    func addNote(noteText: String, photo: URL?, withLocation: Bool)
    func deleteNote(note: Note, completion: @escaping () -> Void)
    func updateNote(note: Note, newText: String, completion: @escaping () -> Void)
    func getNotes(completion: @escaping ([Note]) -> Void)
    func fetchSpecifiedNote(number: Int, completion: @escaping (Note) -> Void)
    var observer: (() -> Void)? { get set }
}

@objc
class NotesHandlerDefault: NSObject, NotesHandler, NSFetchedResultsControllerDelegate {
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    var sessionUUID: SessionUUID
    @Injected private var locationTracker: LocationTracker
    @Injected private var sessionUpdateService: SessionUpdateService
    @Injected private var persistenceController: PersistenceController
    var observer: (() -> Void)?

    private lazy var frc: NSFetchedResultsController<NoteEntity> = {
        let fetchRequest = NoteEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "text", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: persistenceController.viewContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    init(sessionUUID: SessionUUID) {
        self.sessionUUID = sessionUUID
        super.init()
        frc.delegate = self
        try? frc.performFetch()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?()
    }

    func addNote(noteText: String, photo: URL?, withLocation: Bool) {
        let latitude = withLocation ? locationTracker.locationManager.location?.coordinate.latitude ?? locationTracker.googleLocation.last?.location.latitude ?? 20.0 : 20.0
        let longitude = withLocation ? locationTracker.locationManager.location?.coordinate.longitude ?? locationTracker.googleLocation.last?.location.longitude ?? 20.0 : 20.0
        Log.info("## PHOTO: \(photo)")
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                let currentNumber = try storage.getNotes(for: sessionUUID).map(\.number).sorted(by: < ).last
                try storage.addNote(Note(date: DateBuilder.getFakeUTCDate(),
                                         text: noteText,
                                         lat: latitude,
                                         long: longitude,
                                         photoLocation: photo,
                                         number: (currentNumber ?? -1) + 1),
                                    for: sessionUUID)
            } catch {
                Log.info("Error when adding to DB: \(error)")
            }
        }
    }

    func deleteNote(note: Note, completion: @escaping () -> Void) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.deleteNote(note, for: self.sessionUUID)
                self.fetchSession(storage: storage) { session in
                    self.sessionUpdateService.updateSession(session: session) { result in
                        switch result {
                        case .success(let updateData):
                            self.measurementStreamStorage.accessStorage { storage in
                                try? storage.updateVersion(for: self.sessionUUID, to: updateData.version)
                                Log.info("Notes successfully updated")
                                completion()
                            }
                        case .failure(let error):
                            Log.info("Failed updating session while updating notes: \(error.localizedDescription)")
                            completion()
                        }
                    }
                }
            } catch {
                Log.info("Error when deleting note: \(error)")
            }
        }
    }

    func updateNote(note: Note, newText: String, completion: @escaping () -> Void) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateNote(note, newText: newText, for: sessionUUID)
                fetchSession(storage: storage) { session in
                    self.sessionUpdateService.updateSession(session: session) { result in
                        switch result {
                        case .success(let updateData):
                            self.measurementStreamStorage.accessStorage {storage in
                                try? storage.updateVersion(for: self.sessionUUID, to: updateData.version)
                                Log.info("Notes successfully updated")
                                completion()
                            }
                        case .failure(let error):
                            Log.info("Failed updating session while updating notes: \(error.localizedDescription)")
                            completion()
                        }
                    }
                }
            } catch {
                Log.info("Error when updating note: \(error)")
            }
        }
    }

    func getNotes(completion: @escaping ([Note]) -> Void) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                completion(try storage.getNotes(for: sessionUUID))
            } catch {
                Log.info("Error when getting all notes: \(error)")
            }
        }
    }

    func fetchSpecifiedNote(number: Int, completion: @escaping (Note) -> Void) {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                completion(try storage.fetchSpecifiedNote(for: sessionUUID, number: number))
            } catch {
                Log.info("Error when fetching note: \(error)")
            }
        }
    }
}

// MARK: Internal methods
extension NotesHandlerDefault {
    private func fetchSession(storage: HiddenCoreDataMeasurementStreamStorage, completion: @escaping (SessionEntity) -> Void) {
        do {
            completion(try storage.getExistingSession(with: sessionUUID))
        } catch {
            Log.info("Error when fetching session: \(error)")
        }
    }
}
