// Created by Lunar on 05/01/2022.
//

import Foundation

class MapNotesViewModelDefault {
    var notesHandler: NotesHandler
    
    init(notesHandler: NotesHandler) {
        self.notesHandler = notesHandler
    }
    
    func prepareNotesForMap(completion: @escaping ([Note]) -> Void) {
        notesHandler.getNotesFromDatabase { notes in
            completion(notes)
        }
    }
}

class DummyMapNotesViewModelDefault: MapNotesViewModelDefault {
    
}
