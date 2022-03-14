// Created by Lunar on 24/01/2022.
//
import Foundation

// swiftlint:disable airCasting_date
class DateBuilder {
    /// To match the Android app and the backend, we need to simulate the current taken Date() as the UTC.
    /// This is the main function, which should replace standard Date(), in our case getRawDate() in most of the places.
    static func getFakeUTCDate() -> Date {
        Date().currentUTCTimeZoneDate
    }
    /// Represent standard Date(), without any conversion/simulation.
    static func getRawDate() -> Date {
        Date()
    }
    
    static func getDateWithTimeIntervalSince1970(_ timeInterval: Double) -> Date {
        Date(timeIntervalSince1970: timeInterval)
    }
    
    static func getTimeIntervalSince1970() -> Double {
        Date().timeIntervalSince1970
    }
    
    static func beginingOfCurrentDayInSeconds() -> Double {
        Calendar.current.startOfDay(for: getFakeUTCDate()).timeIntervalSince1970
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
    
    static func getDateWithTimeIntervalSinceReferenceDate(_ timeInterval: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    static func distantPast() -> Date {
        Date.distantPast
    }
    
    static func distantFuture() -> Date {
        Date.distantFuture
    }
    
    static func yearAgo() -> Date {
       getFakeUTCDate() - (365 * 24 * 60 * 60)
    }
}
// swiftlint:enable airCasting_date
