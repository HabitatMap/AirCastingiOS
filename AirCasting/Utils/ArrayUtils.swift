// Created by Lunar on 14/06/2021.
//

import Foundation

extension Array {
    init(creating: @autoclosure () -> Element, times: Int) {
        self = (0..<times).map { _ in creating() }
    }
}

extension Array where Element: Equatable {
    func containsSameElements(as otherArray: Self) -> Bool {
        guard self.count == otherArray.count else { return false }
        return allSatisfy { count(of: $0) == otherArray.count(of: $0) }
    }
}

extension Array where Element: Equatable {
    func count(of element: Element) -> Int {
        filter({ $0 == element }).count
    }
}
