// Created by Lunar on 19/10/2021.
//

import Foundation

extension Int {
    var isEven: Bool {
        self % 2 == 0
    }
}

extension RandomAccessCollection {
    var middleItemIndex: (Index) {
        /// We 
        let evenIdx = index(startIndex, offsetBy: count / 2 - 1)
        let oddIdx = index(startIndex, offsetBy: count / 2)
        return count.isEven ? evenIdx : oddIdx
    }
}
