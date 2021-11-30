// Created by Lunar on 30/11/2021.
//

import Foundation

struct FinishSessionOptions: OptionSet {
    static let omitDatabaseUpdate = FinishSessionOptions(rawValue: 1)
    static let dontTriggerSync = FinishSessionOptions(rawValue: 1 << 1)
    
    let rawValue: Int8
}
