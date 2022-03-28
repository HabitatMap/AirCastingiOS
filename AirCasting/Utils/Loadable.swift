// Created by Lunar on 23/03/2022.
//

import Foundation

enum Loadable<T> {
    case loading
    case ready(T)
    
    var isReady: Bool {
        switch self {
        case .ready: return true
        case .loading: return false
        }
    }
    
    var get: T? {
        switch self {
        case .loading: return nil as T?
        case .ready(let item): return item
        }
    }
}
