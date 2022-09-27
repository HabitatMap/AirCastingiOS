// Created by Lunar on 30/08/2022.
//
import Foundation

extension Sequence {
    func mapWithNext(_ map: ((Element, Element) -> Element)) -> [Element] {
        var iter = self.makeIterator()
        var prev = iter.next()
        guard prev != nil else { return [] }
        
        var pairs: [(Element, Element)] = []
        while let elem = iter.next() {
            pairs.append((prev!, elem))
            prev = elem
        }
        var transformed = pairs.map { map($0.0, $0.1) }
        transformed.append(pairs.last!.1)
        transformed = transformed.reversed()
        return transformed
    }
}
