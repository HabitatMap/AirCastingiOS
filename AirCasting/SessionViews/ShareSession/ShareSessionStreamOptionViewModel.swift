// Created by Lunar on 16/12/2021.
//

import Foundation

struct ShareSessionStreamOptionViewModel {
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
