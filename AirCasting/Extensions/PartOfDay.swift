// Created by Lunar on 22/03/2022.
//

import Foundation


// swiftlint:disable airCasting_date
extension Date {
    var yearAgo: Date {
        self.currentUTCTimeZoneDate - (365 * 24 * 60 * 60)
    }
    
    var beginingOfCurrentDayInSeconds: Double {
        Calendar.current.startOfDay(for: self.currentUTCTimeZoneDate).timeIntervalSince1970
    }
}
// swiftlint:enable airCasting_date
