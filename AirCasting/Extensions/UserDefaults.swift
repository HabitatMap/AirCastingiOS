// Created by Lunar on 06/01/2022.
//

import Foundation

extension UserDefaults {

    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }

}
