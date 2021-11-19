// Created by Lunar on 19/11/2021.
//

import Foundation

public struct ThresholdsValue {
    let veryLow: Int32
    let low: Int32
    let medium: Int32
    let high: Int32
    let veryHigh: Int32
    
    var toArray: [Int32] {
        [veryLow, low, medium, high, veryHigh]
    }
    
    init(array: [Int32]) {
        assert(array.count == 5)
        veryLow = array[0]
        low = array[1]
        medium = array[2]
        high = array[3]
        veryHigh = array[4]
    }
    
    public init(veryLow: Int32, low: Int32, medium: Int32, high: Int32, veryHigh: Int32) {
        self.veryLow = veryLow
        self.low = low
        self.medium = medium
        self.high = high
        self.veryHigh = veryHigh
    }
}
