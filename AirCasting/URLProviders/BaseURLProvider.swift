// Created by Lunar on 28/06/2021.
//

import Foundation

protocol BaseURLProvider {
    var baseAppURL: URL { get set }
}

protocol isSessionSynchronizing {
    var syncIsInProgress: Bool { get set }
}

#if DEBUG
struct DummyURLProvider: BaseURLProvider {
    var baseAppURL: URL = URL(string: "http://aircasting.org/api")!
}
#endif
