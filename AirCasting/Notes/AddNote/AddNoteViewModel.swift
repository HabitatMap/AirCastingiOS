// Created by Lunar on 16/12/2021.
//
import Foundation

protocol AddNoteViewModel: ObservableObject {
    var noteText: String { get set }
    func cancelTapped()
}

class AddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void) {
        self.exitRoute = exitRoute
    }
    
    func cancelTapped() { exitRoute() }
}

class DummyAddNoteViewModelDefault: AddNoteViewModel, ObservableObject {
    @Published var noteText = ""
    
    func cancelTapped() { print("Cancel tapped") }
}
