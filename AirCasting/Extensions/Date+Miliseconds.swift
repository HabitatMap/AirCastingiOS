// Created by Lunar on 10/08/2021.
//

import Foundation

extension Date {
    static let msFormatter: DateFormatter = DateFormatters.DateExtension.milisecondsDateFormatter
    
    var milliseconds: Int {
        Int(Date.msFormatter.string(from: self).dropFirst())!
    }

    var currentUTCTimeZoneDate: Date {
        let formatter = DateFormatters.DateExtension.currentTimeZoneDateFormatter
        let stringDate = formatter.string(from: self)
        let dateFormatter = DateFormatters.DateExtension.utcTimeZoneDateFormatter
        return dateFormatter.date(from: stringDate)!
    }
}
