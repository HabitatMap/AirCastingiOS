// Created by Lunar on 25/06/2021.
//

import Foundation

struct LocalizedErrorStub: Error, LocalizedError {
    var errorDescription: String?
    
    init(string: String) {
        errorDescription = string
    }
}
