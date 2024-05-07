// Created by Lunar on 28/06/2021.
//

import Foundation

protocol URLProvider: AnyObject {
    var baseAppURL: URL { get set }
}

#if DEBUG
class DummyURLProvider: URLProvider, ObservableObject {
    var baseAppURL: URL = URL(string: "http://45.56.103.151")!
}
#endif
