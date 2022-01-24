// Created by Lunar on 24/01/2022.
//
import Foundation

// swiftlint:disable airCasting_date
class DateBuilder {
    static func getDate() -> Date {
        Date().currentUTCTimeZoneDate
    }
    
    static func getRawDate() -> Date {
        Date()
    }
    
    static func getSince1970using(_ timeInterval: Double) -> Date {
        Date(timeIntervalSince1970: timeInterval)
    }
    
    static func getSince1970() -> Double {
        Date().timeIntervalSince1970
    }
    
    static func getSince(timeInterval: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    static func distantPast() -> Date {
        Date.distantPast
    }
    
    static func distantFuture() -> Date {
        Date.distantFuture
    }
    
    static func msFormat(_ date: Date) -> String {
        Date.msFormatter.string(from: date)
    }
}
// swiftlint:enable airCasting_date
