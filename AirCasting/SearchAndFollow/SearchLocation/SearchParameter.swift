// Created by Lunar on 20/04/2022.
//

import Foundation

class SearchParameter: Identifiable {
    let id = UUID()
    var isSelected: Bool
    let name: String
    
    init(isSelected: Bool, name: String) {
        self.isSelected = isSelected
        self.name = name
    }
}
