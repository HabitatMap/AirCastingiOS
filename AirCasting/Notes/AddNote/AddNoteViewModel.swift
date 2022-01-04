// Created by Lunar on 16/12/2021.
//
import Foundation

protocol AddNoteViewModel: ObservableObject {
    var noteText: String { get set }
    func continueTapped()
    func cancelTapped()
}

class AddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    var notesHandler: NotesHandler
    var locationTracker: LocationTracker
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void, notesHandler: NotesHandler, locationTracker: LocationTracker) {
        self.notesHandler = notesHandler
        self.exitRoute = exitRoute
        self.locationTracker = locationTracker
    }
    
    func continueTapped() {
        notesHandler.addNoteToDatabase(note: Note(date: Date(),
                                                  text: noteText,
                                                  lat: locationTracker.googleLocation.last?.location.latitude ?? 20.0,
                                                  long: locationTracker.googleLocation.last?.location.longitude ?? 20.0,
                                                  number: notesHandler.obtainNumber()))
        exitRoute()
    }
    
    func cancelTapped() { exitRoute() }
}

class DummyAddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    func continueTapped() { print("Clicked continue") }
    func cancelTapped() { print("Cancel tapped") }
}
