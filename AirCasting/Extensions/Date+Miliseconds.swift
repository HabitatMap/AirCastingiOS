// Created by Lunar on 10/08/2021.
//

import Foundation

extension Date {
    static let msFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "SSS"
        return f
    }()
    
    var milliseconds: Int {
        Int(Date.msFormatter.string(from: self).dropFirst())!
    }
}
