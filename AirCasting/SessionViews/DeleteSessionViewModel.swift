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
    #warning("Abstract microphone sessions away") 
    var isMicrophone: Bool { get }
    var options: [DeleteSessionOptionViewModel] { get }
    var deleteEnabled: Bool { get }
    func didSelect(option: DeleteSessionOptionViewModel)
    func deleteSelected()
    func isNotMicrophoneToggle()
    func isMicrophoneToggle()
}
