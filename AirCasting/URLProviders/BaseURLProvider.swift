// Created by Lunar on 28/06/2021.
//

import Foundation

protocol BaseURLProvider {
    var baseAppURL: URL { get set }
    var authorizationURL: URL { get }
}

extension BaseURLProvider {
    var authorizationURL: URL {
        URL(string: "http://aircasting.org/api")!
    }
}

#if DEBUG
struct DummyURLProvider: BaseURLProvider {
    var baseAppURL: URL = URL(string: "http://aircasting.org/api")!
}
#endif
