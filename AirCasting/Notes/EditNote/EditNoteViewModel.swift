// Created by Lunar on 16/12/2021.
//
import Foundation
import Resolver

protocol EditNoteViewModel: ObservableObject {
    var noteText: String { get set }
    var notePhoto: URL? { get set }
    var shouldShowError: Bool { get set }
    func saveTapped()
    func deleteTapped()
    func cancelTapped()
}

class EditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    @Published var noteText = ""
    @Published var notePhoto: URL? = nil
    @Published var shouldShowError = false
    private var note: Note!
    private let notesHandler: NotesHandler
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void, noteNumber: Int, sessionUUID: SessionUUID) {
        Log.verbose("Started editing note no. \(noteNumber) for session: \(sessionUUID)")
        self.exitRoute = exitRoute
        self.notesHandler = Resolver.resolve(NotesHandler.self, args: sessionUUID)
        
        notesHandler.fetchSpecifiedNote(number: noteNumber) { note in
            DispatchQueue.main.async {
                self.note = note
                self.noteText = note.text
                self.notePhoto = note.photoLocation
            }
        }
    }
    
    func saveTapped() {
        guard !noteText.isEmpty else {
            shouldShowError = true
            return
        }
        notesHandler.updateNote(note: note, newText: noteText, completion: {
            self.exitRoute()
        })
    }
    
    func deleteTapped() {
        notesHandler.deleteNote(note: note, completion: { [weak self] in
            self?.exitRoute()
        })
    }
    
    func cancelTapped() {
        exitRoute()
    }
}
