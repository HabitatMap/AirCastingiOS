// Created by Lunar on 10/08/2022.
//

import Foundation

struct MapPositioning {
    let fixed: Bool
    let live: Bool
    
    init(fixed: Bool = false, live: Bool = false) {
        self.fixed = fixed
        self.live = live
    }
}
