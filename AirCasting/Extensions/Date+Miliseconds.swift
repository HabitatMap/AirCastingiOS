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

    var currentUTCTimeZoneDate: Date {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let stringDate = formatter.string(from: self)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.init(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: stringDate)!
    }
}
