// Created by Lunar on 05/01/2022.
//

import Foundation

class EmptyNotesHandler: NotesHandler {
    func updateNoteInDatabase(note: Note, newText: String) {
        fatalError()
    }
    
    func addNoteToDatabase(note: Note) {
        fatalError()
    }
    
    func markWithNumberID() -> Int {
        fatalError()
    }
    
    func fetchSpecifiedNote(number: Int) -> Note {
        fatalError()
    }
    
    func deleteNoteFromDatabase(note: Note) {
        fatalError()
    }
    
    func getNotesFromDatabase(completion: ([Note]) -> Void) {
        completion([])
    }
    
    func fetchSpecifiedNote(number: Int, completion: (Note) -> Void) {
        fatalError()
    }
}
