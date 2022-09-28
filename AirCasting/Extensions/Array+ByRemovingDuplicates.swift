// Created by Lunar on 30/08/2022.
//
import Foundation

extension Array where Element: Equatable {
    /// Iterates all elements and gets rid of the duplicates using provided strategy
    /// - Parameter strategy: a block invoked when conflict appears. It an `Element` that causes collision as a parameter.
    /// If this block returns `nil`, the new element won't be added to the resulting array.
    /// If it returns a value, this value will be added to the resulting array.
    /// - Returns: A new `Array` with conflicts resolved.
    func eliminateDuplicates(using strategy: (_ colliding: Element) -> Element?) -> Self {
        var buffer: Self = []
        for element in self {
            appendBuffer(&buffer, with: element, strategy: strategy)
        }
        return buffer
    }
    
    private func appendBuffer(_ buffer: inout Self, with value: Element, strategy: (_ colliding: Element) -> Element?) {
        guard buffer.contains(value) else {
            buffer.append(value)
            return
        }
        
        if let modified = strategy(value) {
            appendBuffer(&buffer, with: modified, strategy: strategy)
        }
    }
}
