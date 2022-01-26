// Created by Lunar on 16/12/2021.
//
import Foundation

protocol EditNoteViewModel: ObservableObject {
    var noteText: String { get set }
    func saveTapped()
    func deleteTapped()
    func cancelTapped()
}

class EditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    @Published var noteText = Strings.Commons.note
    private var note: Note!
    private var notesHandler: NotesHandler
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void, noteNumber: Int, notesHandler: NotesHandler) {
        self.exitRoute = exitRoute
        self.notesHandler = notesHandler
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
        notesHandler.deleteNote(note: note, completion: { [weak self] in
            self?.exitRoute()
        })
    }
    
    func cancelTapped() {
        exitRoute()
    }
}

class DummyEditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    
    @Published var noteText = ""
    
    func saveTapped() { Log.info("Save tapped") }
    
    func deleteTapped() { Log.info("Delete tapped") }
    
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void) {
        self.exitRoute = exitRoute
    }
    
    func cancelTapped() { exitRoute() }
}
