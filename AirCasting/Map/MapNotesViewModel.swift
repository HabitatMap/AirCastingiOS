// Created by Lunar on 05/01/2022.
//

import Foundation
import CoreLocation
import UIKit
import Resolver

struct MapNote: Identifiable {
    let id: Int
    let location: CLLocationCoordinate2D
    let markerImage: UIImage
}

class MapNotesViewModel: ObservableObject {
    @Published var notes: [MapNote] = []
    private var notesHandler: NotesHandler
    
    init(sessionUUID: SessionUUID) {
        self.notesHandler = Resolver.resolve(NotesHandler.self, args: sessionUUID)
        refreshNotes()
        self.notesHandler.observer = { [weak self] in
            self?.refreshNotes()
        }
    }
    
    private func refreshNotes() {
        notesHandler.getNotes { notes in
            DispatchQueue.main.async {
                self.notes = notes.map({ note in
                        .init(id: note.number,
                              location: .init(latitude: note.lat, longitude: note.long),
                              markerImage: UIImage(named: "message-square")!.withRenderingMode(.alwaysTemplate))
                })
            }
        }
    }
}
