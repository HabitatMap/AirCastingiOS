// Created by Lunar on 16/12/2021.
//
import Foundation
import Resolver

class AddNoteViewModel: ObservableObject {
    @Injected private var locationTracker: LocationTracker
    @Published var noteText = Strings.Commons.note
    
    private let notesHandler: NotesHandler
    private let exitRoute: () -> Void
    private let trackLocation: Bool
    
    init(sessionUUID: SessionUUID, withLocation: Bool, exitRoute: @escaping () -> Void) {
        self.exitRoute = exitRoute
        self.notesHandler = Resolver.resolve(NotesHandler.self, args: sessionUUID)
        trackLocation = withLocation
    }
    
    func continueTapped() {
        if let latitude = locationTracker.locationManager.location?.coordinate.latitude,
           let longitude = locationTracker.locationManager.location?.coordinate.longitude,
           trackLocation {
            notesHandler.addNote(noteText: noteText, latitude: latitude, longitude: longitude)
        }
        notesHandler.addNote(noteText: noteText, latitude: 20.0, longitude: 20.0)
        exitRoute()
    }

    func cancelTapped() { exitRoute() }
}
