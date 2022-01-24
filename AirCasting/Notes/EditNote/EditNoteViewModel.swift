// Created by Lunar on 16/12/2021.
//
import Foundation
import Resolver

protocol EditNoteViewModel: ObservableObject {
    var noteText: String { get set }
    func saveTapped()
    func deleteTapped()
    func cancelTapped()
}

class EditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    @Published var noteText = Strings.Commons.note
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
            }
        }
    }
    
    func saveTapped() {
        notesHandler.updateNote(note: note, newText: noteText, completion: {
            self.exitRoute()
        })
    }
    
    func deleteTapped() {
        notesHandler.deleteNote(note: note); exitRoute()
    }
    
    func cancelTapped() {
        exitRoute()
    }
}
