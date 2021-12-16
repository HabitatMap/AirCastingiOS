// Created by Lunar on 16/12/2021.
//
import Foundation

protocol EditNoteViewModel: ObservableObject {
    var noteText: String { get set }
}

class EditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    @Published var noteText = ""
}


class DummyEditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
}
