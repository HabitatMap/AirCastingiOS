// Created by Lunar on 19/06/2021.
//

import Foundation

struct DummyError: Error, Equatable, LocalizedError {
    let errorData: String
    var errorDescription: String? { errorData }
    
    init(errorData: String = .default) {
        self.errorData = errorData
    }
}
