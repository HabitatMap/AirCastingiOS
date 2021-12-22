// Created by Lunar on 16/12/2021.
//
import Foundation

protocol AddNoteViewModel: ObservableObject {
    var noteText: String { get set }
    
    func continueClicked(note: Note)
    func cancelTapped()
}

class AddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    var notesHandler: NotesHandler
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void, notesHandler: NotesHandler) {
        self.notesHandler = notesHandler
        self.exitRoute = exitRoute
    }
    
    func continueClicked(note: Note) { notesHandler.addNoteToDatabase(note: note) }
    
    func cancelTapped() { exitRoute() }
}

class DummyAddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    func continueClicked(note: Note) { }
    func cancelTapped() { print("Cancel tapped") }
}
