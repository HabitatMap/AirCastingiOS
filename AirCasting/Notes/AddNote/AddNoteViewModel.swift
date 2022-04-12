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
        guard let latitude = locationTracker.locationManager.location?.coordinate.latitude,
              let longitude = locationTracker.locationManager.location?.coordinate.longitude,
              trackLocation else {
            notesHandler.addNote(noteText: noteText, latitude: 20.0, longitude: 20.0)
            exitRoute()
            return
        }
        notesHandler.addNote(noteText: noteText, latitude: latitude, longitude: longitude)
        exitRoute()
    }

    func cancelTapped() { exitRoute() }
}
