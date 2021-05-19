// Created by Lunar on 03/05/2021.
//

import Foundation

func diff<T1, T2>(_ first: [T1], _ second: [T2], with compare: (_ first: T1, _ second: T2) -> Bool, with compare2: (T2, T2) -> Bool) -> (common: [(T1, T2)], removed: [T1], inserted: [T2]) {
    if first.isEmpty {
        return (common: [], removed: [], inserted: second)
    }
    if second.isEmpty {
        return (common: [], removed: first, inserted: [])
    }
    var common: [(T1, T2)] = []
    var removed: [T1] = []
    var inserted: [T2] = []
    var handledJ: [T2] = []
    outer: for i in first {
        for j in second {
            if compare(i, j) {
                common.append((i, j))
                handledJ.append(j)
                continue outer
            }
        }
        removed.append(i)
    }
    for j in second {
        if handledJ.contains(where: { compare2($0, j)}) {
            continue
        }
        inserted.append(j)
    }
    return (common: common, removed: removed, inserted: inserted)
}

func diff<T1, T2: Equatable>(_ first: [T1], _ second: [T2], with compare:(_ first: T1, _ second: T2) -> Bool) -> (common: [(T1, T2)], removed: [T1], inserted: [T2]) {
    diff(first, second, with: compare, with: ==)
}

func diff<T1, T2: AnyObject>(_ first: [T1], _ second: [T2], with compare:(_ first: T1, _ second: T2) -> Bool) -> (common: [(T1, T2)], removed: [T1], inserted: [T2]) {
    diff(first, second, with: compare, with: ===)
}

func diff<T1: Identifiable, T2: Equatable & Identifiable>(_ first: [T1], _ second: [T2]) -> (common: [(T1, T2)], removed: [T1], inserted: [T2]) where T1.ID == T2.ID {
    diff(first, second, with: { $0.id == $1.id }, with: ==)
}
