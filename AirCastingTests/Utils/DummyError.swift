// Created by Lunar on 19/06/2021.
//

import Foundation

struct DummyError: Error, Equatable {
    let errorData: String
    
    init(errorData: String = .default) {
        self.errorData = errorData
    }
}
