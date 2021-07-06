// Created by Lunar on 05/07/2021.
//

import Foundation

extension TimeInterval {
    static var minute: Self {
        60
    }
    
    static var day: Self {
        minute * 60 * 24
    }
    
    static var week: Self {
        day * 7
    }
}
