// Created by Lunar on 16/07/2021.
//

import Foundation

struct DeleteSessionOptionViewModel {
    let id: Int
    let title: String
    var isSelected: Bool
    let isEnabled: Bool

    mutating func toggleSelection() {
        isSelected.toggle()
    }

    mutating func changeSelection(newSelected: Bool) {
        isSelected = newSelected
    }
}

protocol DeleteSessionViewModel: ObservableObject {
    var streamOptions: [DeleteSessionOptionViewModel] { get }
    var deleteEnabled: Bool { get }
    var showingConfirmationAlert: Bool { get set }
    func didSelect(option: DeleteSessionOptionViewModel)
    func deleteSelected()
    func showConfirmationAlert()
}
