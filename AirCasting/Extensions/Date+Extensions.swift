// Created by Lunar on 10/08/2021.
//

import Foundation
// swiftlint:disable airCasting_date
extension Date {
    
    static let msFormatter: DateFormatter = DateFormatters.DateExtension.milisecondsDateFormatter
    
    var milliseconds: Int {
        Int(Date.msFormatter.string(from: self).dropFirst())!
    }
    
    var millisecondsSinceReferenceDate: Int {
        Int((self.timeIntervalSince1970 * 1000.0).rounded())
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

    /// Move a BE-supplied real-UTC `Date` to the fakeUTC convention iOS uses
    /// internally (wall-clock numerals as a UTC moment in the phone's TZ).
    /// Returns the date unchanged when `isIndoor` is `false` — the parameter
    /// is named for the original caller's indoor-vs-outdoor split, but the
    /// underlying semantics is simply "apply the BE-UTC → phone-wall-clock
    /// shift". `UpdateSessionParamsService` derives the bool per timestamp
    /// kind: V2 fixed `Session#start_time` always needs the shift (BE writes
    /// the production server clock without `to_local_as_utc`), while V2
    /// `Session#end_time` and `Measurement#time` only need it when BE's
    /// `session.time_zone` defaults to UTC (indoor / locationless).
    func shiftedForFixedSession(isIndoor: Bool) -> Date {
        guard isIndoor else { return self }
        return self.currentUTCTimeZoneDate
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
    
    var twentyFourHoursBeforeInSeconds: Double {
        let twentyFourHours = 86400000 // 24 hours in miliseconds: 60 * 60 * 24
        return Double(self.millisecondsSinceReferenceDate - twentyFourHours)/1000
    }
}
