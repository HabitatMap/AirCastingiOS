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
        Date.yearAgo()
    }
    
    static func beginingOfCurrentDayInSeconds() -> Double {
        Date.beginingOfCurrentDayInSeconds()
    }
    
    static func beginingOfDayInSeconds(using date: Date) -> Double {
        Date.beginingOfDayInSeconds(using: date)
    }
    
    static func endOfDayInSeconds(using date: Date) -> Double {
        Date.endOfDayInSeconds(using: date)
    }
}
// swiftlint:enable airCasting_date
