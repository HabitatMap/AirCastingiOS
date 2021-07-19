// Created by Lunar on 16/07/2021.
//

import Foundation

class DefaultDeleteSessionViewModel: DeleteSessionViewModel {
    
    func isNotMicrophoneToggle() {
        isMicrophone = false
    }
    
    func isMicrophoneToggle() {
        isMicrophone = true
    }
    
    var isMicrophone: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    var deleteEnabled: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    func deleteSelected() {
        #warning("TODO: Implement me")
    }
    
    func didSelect(option: DeleteSessionOptionViewModel) {
        guard let index = options.firstIndex(where: { $0.id == option.id }) else {
            assertionFailure("Unknown option index")
            return
        }
        options[index].toggleSelection()
        if index == 0 {
            for i in options.indices {
                options[i].changeSelection(newSelected: options[0].isSelected)
            }
        }
    }
    
    // It is variable because of the following scenario :
    // 1. Go to delete session scene
    // 2. Remove one of the streams on different device
    // 3. It should after sync it should get removed from the view
    
    var options: [DeleteSessionOptionViewModel] {
        willSet {
            objectWillChange.send()
        }
    }
    
    init() {
        #warning("TODO: When implementing please provide real data")
        options =  !isMicrophone ? [.init(id: 0, title: "All", isSelected: false, isEnabled: false),
                                    .init(id: 1, title: "PM1", isSelected: false, isEnabled: false),
                                    .init(id: 2, title: "PM2.5", isSelected: false, isEnabled: false),
                                    .init(id: 3, title: "RH", isSelected: false, isEnabled: false),
                                    .init(id: 4, title: "F", isSelected: false, isEnabled: false)] : [.init(id: 0, title: "All", isSelected: false, isEnabled: false)]
    }
}
