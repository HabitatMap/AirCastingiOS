// Created by Lunar on 05/02/2022.
//

import Foundation

extension DateFormatter {
    convenience init(format: String) {
        self.init()
        self.dateFormat = format
    }
    
    convenience init(format: String, timezone: TimeZone = .current, locale: Locale = .current) {
        self.init(format: format)
        self.timeZone = timezone
        self.locale = locale
    }
}

extension TimeZone {
    static var utc: Self { TimeZone(identifier: "UTC")! }
}
