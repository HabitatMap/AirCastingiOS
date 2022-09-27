// Created by Lunar on 16/08/2022.
//

import Foundation

extension Numeric {
    func createArrayWithHigherValuesOnly(count: Int) -> [Self] {
        assert(count >= 1)
        let higherValue = self + 1
        var array = [Self](repeating: higherValue, count: count - 1)
        array.insert(self, at: 1)
        return array
    }
    
    func createArrayWithLowerValuesOnly(count: Int) -> [Self] {
        assert(count >= 1)
        let lowerValue = self - 1
        var array = [Self](repeating: lowerValue, count: count - 1)
        array.insert(self, at: 1)
        return array
    }
}
