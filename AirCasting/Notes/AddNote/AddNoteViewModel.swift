// Created by Lunar on 16/12/2021.
//
import Foundation

protocol AddNoteViewModel: ObservableObject {
    var noteText: String { get set }
    func continueClicked(note: Note)
}

class AddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    var notesHandler: NotesHandler
    
    init(notesHandler: NotesHandler) {
        self.notesHandler = notesHandler
    }
    
    func continueClicked(note: Note) { notesHandler.addNoteToDatabase(note: note) }
}


class DummyAddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    func continueClicked(note: Note) { }
}
