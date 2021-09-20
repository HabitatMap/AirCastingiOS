// Created by Lunar on 09/09/2021.
//

import Foundation

final class TimeConverter {
    
    static let df: DateFormatter = DateFormatter()
    
    static func is24Hour() -> Bool {
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!
        return dateFormat.firstIndex(of: "a") == nil
    }
}
