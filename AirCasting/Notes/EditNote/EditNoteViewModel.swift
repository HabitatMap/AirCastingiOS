// Created by Lunar on 16/12/2021.
//
import Foundation

protocol EditNoteViewModel: ObservableObject {
    var noteText: String { get set }
    
    func cancelTapped()
}

class EditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    @Published var noteText = ""
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void) {
        self.exitRoute = exitRoute
    }
    
    func cancelTapped() {
        exitRoute()
    }
}


class DummyEditNoteViewModelDefault: EditNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    func cancelTapped() { }
}
