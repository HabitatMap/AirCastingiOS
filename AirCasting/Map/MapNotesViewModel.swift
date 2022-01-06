// Created by Lunar on 05/01/2022.
//

import Foundation
import CoreLocation
import UIKit

struct MapNote {
    let id: Int
    let location: CLLocationCoordinate2D
    let markerImage: UIImage
}

class MapNotesViewModelDefault: ObservableObject {
    @Published var notes: [MapNote] = []
    private let notesHandler: NotesHandler
    
    init(notesHandler: NotesHandler) {
        self.notesHandler = notesHandler
        notesHandler.getNotesFromDatabase { notes in
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

class DummyMapNotesViewModelDefault: MapNotesViewModelDefault {
    
}
