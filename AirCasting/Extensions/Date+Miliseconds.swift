// Created by Lunar on 10/08/2021.
//

import Foundation

extension Date {
    static let msFormatter: DateFormatter = DateFormatters.DateExtension.milisecondsDateFormatter
    
    var milliseconds: Int {
        Int(DateBuilder.msFormat(self).dropFirst())!
    }

    var currentUTCTimeZoneDate: Date {
        let formatter = DateFormatters.DateExtension.currentTimeZoneDateFormatter
        let stringDate = formatter.string(from: self)
        let dateFormatter = DateFormatters.DateExtension.utcTimeZoneDateFormatter
        return dateFormatter.date(from: stringDate)!
    }

    var roundedDownToSecond: Date {
        let date = self
        return DateBuilder.getSince(timeInterval: date.timeIntervalSinceReferenceDate.rounded(.towardZero))
    }

    var roundedUpToHour: Date {
        let date = self
        return DateBuilder.getSince(timeInterval: (date.timeIntervalSinceReferenceDate / 3600.0).rounded(.awayFromZero) * 3600.0)
    }
    
    var roundedDownToHour: Date {
        let date = self
        return DateBuilder.getSince(timeInterval: (date.timeIntervalSinceReferenceDate / 3600.0).rounded(.towardZero) * 3600.0)
    }
}
