// Created by Lunar on 27/09/2022.
//

import Foundation

extension Array where Element: Equatable & Numeric {
    var incrementRemovalStrategy: (Element) -> Element? {
        { $0.decrement() }
    }
}
