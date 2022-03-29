// Created by Lunar on 10/08/2021.
//

import Foundation
// swiftlint:disable airCasting_date
extension Date {
    static let msFormatter: DateFormatter = DateFormatters.DateExtension.milisecondsDateFormatter
    
    var milliseconds: Int {
        Int(Date.msFormatter.string(from: self).dropFirst())!
    }

    // TODO: This uses two date formatters. It's relatively slow and should be changed to more roboust solution as we're using this quite often
    // https://github.com/HabitatMap/AirCastingiOS/issues/595
    var currentUTCTimeZoneDate: Date {
        let formatter = DateFormatters.DateExtension.currentTimeZoneDateFormatter
        let stringDate = formatter.string(from: self)
        let dateFormatter = DateFormatters.DateExtension.utcTimeZoneDateFormatter
        return dateFormatter.date(from: stringDate)!
    }
    
    // TODO: This uses two date formatters. It's relatively slow and should be changed to more roboust solution as we're using this quite often
    // https://github.com/HabitatMap/AirCastingiOS/issues/595
    var convertedFromUTCToLocal: Date {
        let formatter = DateFormatters.DateExtension.utcTimeZoneDateFormatter
        let stringDate = formatter.string(from: self)
        let dateFormatter = DateFormatters.DateExtension.currentTimeZoneDateFormatter
        return dateFormatter.date(from: stringDate)!
    }

    var roundedDownToSecond: Date {
        let date = self
        return Date(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate.rounded(.towardZero))
    }

    var roundedUpToHour: Date {
        let date = self
        return Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 3600.0).rounded(.awayFromZero) * 3600.0)
    }
    
    var roundedDownToHour: Date {
        let date = self
        return Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 3600.0).rounded(.towardZero) * 3600.0)
    }
    
    static func yearAgo() -> Date {
        DateBuilder.getFakeUTCDate() - (365 * 24 * 60 * 60)
    }
    
    static func beginingOfCurrentDayInSeconds() -> Double {
        Calendar.current.startOfDay(for: DateBuilder.getFakeUTCDate()).timeIntervalSince1970
    }
    
    static func beginingOfDayInSeconds(using date: Date) -> Double {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.utc
        return calendar.startOfDay(for: date).timeIntervalSince1970
    }
    
    static func endOfDayInSeconds(using date: Date) -> Double {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.utc
        return calendar.startOfDay(for: date).timeIntervalSince1970 + (23 * 60 * 60 + 3540 + 59)
    }
}
// swiftlint:enable airCasting_date


extension Date {
    var yearAgo: Date {
        self - (365 * 24 * 60 * 60)
    }
    
    var beginingOfDayInSeconds: Double {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.utc
        return calendar.startOfDay(for: self).timeIntervalSince1970
    }
    
    var endOfDayInSeconds: Double {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.utc
        return calendar.startOfDay(for: self).timeIntervalSince1970 + (23 * 60 * 60 + 3540 + 59)
    }
}
