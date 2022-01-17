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
    @Published var noteText = ""
    private var note: Note!
    private var notesHandler: NotesHandler
    private let exitRoute: () -> Void
    
    
    init(exitRoute: @escaping () -> Void, noteNumber: Int, notesHandler: NotesHandler) {
        self.exitRoute = exitRoute
        self.notesHandler = notesHandler
        notesHandler.fetchSpecifiedNote(number: noteNumber) { note in
            self.note = note
            self.noteText = note.text
        }
    }
    
    func saveTapped() {
        notesHandler.updateNote(note: note, newText: noteText); exitRoute()
    }
    
    func deleteTapped() {
        notesHandler.deleteNote(note: note); exitRoute()
    }
    
    func cancelTapped() {
        exitRoute()
    }
}

class DummyEditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    
    @Published var noteText = ""
    
    func saveTapped() { print("Save tapped") }
    
    func deleteTapped() { print("Delete tapped") }
    
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void) {
        self.exitRoute = exitRoute
    }
    
    func cancelTapped() { exitRoute() }
}
