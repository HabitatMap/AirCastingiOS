// Created by Lunar on 16/12/2021.
//
import Foundation

protocol AddNoteViewModel: ObservableObject {
    var noteText: String { get set }
}

class AddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
}


class DummyAddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
}
