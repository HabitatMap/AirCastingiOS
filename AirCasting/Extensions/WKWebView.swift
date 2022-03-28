// Created by Lunar on 03/03/2022.
//

import Foundation
import WebKit

extension WKWebView {
    func load(_ url: URL?) {
        guard let url = url else {
            return
        }
        
        self.load(.init(url: url))
    }
}
