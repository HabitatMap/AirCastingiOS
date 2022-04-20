// Created by Lunar on 16/12/2021.
//
import Foundation
import Resolver

class AddNoteViewModel: ObservableObject {
    @Published var noteText = Strings.Commons.note
    
    private let notesHandler: NotesHandler
    private let exitRoute: () -> Void
    
    init(sessionUUID: SessionUUID, exitRoute: @escaping () -> Void) {
        self.exitRoute = exitRoute
        self.notesHandler = Resolver.resolve(NotesHandler.self, args: sessionUUID)
    }
    
    func continueTapped() {
        notesHandler.addNote(noteText: noteText)
            exitRoute()
    }

    func cancelTapped() { exitRoute() }
}
