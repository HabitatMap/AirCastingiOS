// Created by Lunar on 16/12/2021.
//
import Foundation

protocol AddNoteViewModel: ObservableObject {
    var noteText: String { get set }
    func continueTapped()
    func cancelTapped()
}

class AddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = Strings.Commons.note
    
    var notesHandler: NotesHandler
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void, notesHandler: NotesHandler) {
        self.notesHandler = notesHandler
        self.exitRoute = exitRoute
    }
    
    func continueTapped() {
        notesHandler.addNote(noteText: noteText)
        exitRoute()
    }

    func cancelTapped() { exitRoute() }
}

class DummyAddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    func continueTapped() { Log.info("Clicked continue") }
    
    func cancelTapped() { Log.info("Cancel tapped") }
}
