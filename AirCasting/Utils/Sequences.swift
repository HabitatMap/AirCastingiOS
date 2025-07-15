// Created by Lunar on 14.07.25.
//

import Foundation

extension Sequence {
    func partitioned(by condition: (Element) -> Bool) -> (matching: [Element], nonMatching: [Element]) {
        var matching = [Element]()
        var nonMatching = [Element]()

        for element in self {
            if condition(element) {
                matching.append(element)
            } else {
                nonMatching.append(element)
            }
        }

        return (matching, nonMatching)
    }
}
