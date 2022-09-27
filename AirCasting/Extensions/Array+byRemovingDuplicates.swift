// Created by Lunar on 30/08/2022.
//
import Foundation

extension Numeric {
    func decrement() -> Self {
        self - 1
    }
}

extension Array where Element: Equatable & Numeric {
    /// Iterates all elements and gets rid of the duplicates using provided strategy
    /// - Parameter strategy: a type of strategy which will be used inside `implement` function.
    /// If this func returns `nil`, the new element won't be added to the resulting array.
    /// If it returns a value, this value will be added to the resulting array.
    /// - Returns: A new `Array` with conflicts resolved.
    
    enum StrategyType {
        case decrementation
        case none
    }
    
    func byRemovingDuplicates(strategy: Self.StrategyType) -> Self {
        var buffer: Self = []
        for element in self {
            appendBuffer(&buffer, with: element, strategy: strategy)
        }
        return buffer
    }
    
    private func appendBuffer(_ buffer: inout Self, with value: Element, strategy: Self.StrategyType) {
        guard buffer.contains(value) else {
            buffer.append(value)
            return
        }
        
        if let modified = implement(strategy, on: value) {
            appendBuffer(&buffer, with: modified, strategy: strategy)
        }
    }
    
    private func implement(_ strategy: Self.StrategyType, on value: Element) -> Element? {
        switch strategy {
        case .decrementation:
            return value.decrement()
        case .none:
            return nil
        }
    }
}
