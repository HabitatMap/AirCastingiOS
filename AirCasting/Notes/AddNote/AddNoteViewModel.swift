// Created by Lunar on 16/12/2021.
//
import Foundation
import Resolver

class AddNoteViewModel: ObservableObject {
    @Published var noteText = ""
    @Published var shouldShowError = false
    
    private let notesHandler: NotesHandler
    private let exitRoute: () -> Void
    private let trackLocation: Bool
    
    init(sessionUUID: SessionUUID, withLocation: Bool, exitRoute: @escaping () -> Void) {
        self.exitRoute = exitRoute
        self.notesHandler = Resolver.resolve(NotesHandler.self, args: sessionUUID)
        trackLocation = withLocation
    }
    
    func continueTapped(selectedPictureURL: URL?) {
        guard !noteText.isEmpty else {
            shouldShowError = true
            return
        }
        notesHandler.addNote(noteText: noteText, photo: selectedPictureURL, withLocation: trackLocation)
        exitRoute()
    }

    func cancelTapped() { exitRoute() }
}
