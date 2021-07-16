// Created by Lunar on 16/07/2021.
//

import Foundation

class DeleteSessionViewModel: ObservableObject {
    
    private let sessionEntity: SessionEntity
    
    struct Stream {
        let title: String
    }
    
    var streams: [Stream] {
        willSet {
            objectWillChange.send()
        }
    }
}
