// Created by Lunar on 05/01/2022.
//

import Foundation

class EmptyNotesHandler: NotesHandler {
    
    func fetchSession(completion: @escaping (SessionEntity) -> Void) {
        fatalError()
    }
    
    func addNote(noteText: String) {
        fatalError()
    }
    
    func updateNote(note: Note, newText: String, completion: @escaping () -> Void) {
        fatalError()
    }
    
    func markWithNumberID() -> Int {
        fatalError()
    }
    
    func fetchSpecifiedNote(number: Int) -> Note {
        fatalError()
    }
    
    func deleteNote(note: Note) {
        fatalError()
    }
    
    func getNotes(completion: ([Note]) -> Void) {
        completion([])
    }
    
    func fetchSpecifiedNote(number: Int, completion: (Note) -> Void) {
        fatalError()
    }
}
