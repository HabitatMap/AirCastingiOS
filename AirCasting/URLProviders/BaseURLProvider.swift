// Created by Lunar on 28/06/2021.
//

import Foundation

protocol BaseURLProvider {
    var baseAppURL: URL { get set }
}

#if DEBUG
class DummyURLProvider: BaseURLProvider, ObservableObject {
    var baseAppURL: URL = URL(string: "http://aircasting.org/")!
}
#endif
