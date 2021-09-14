// Created by Lunar on 09/09/2021.
//

import Foundation

final class TimeConverter {
    
    static let df: DateFormatter = DateFormatter()
    
    static func is24Hour() -> Bool {
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!
        return dateFormat.firstIndex(of: "a") == nil
    }

    static func timeConversion24(time12: String) -> String {
        let dateAsString = time12
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "h:mm a"
        
        let date = df.date(from: dateAsString)
        df.dateFormat = "HH:mm"
        
        let time24 = df.string(from: date!)
        return time24
    }
    
    static func swapDaysAndMonths(date: String) -> String {
        var components = date.components(separatedBy: "/")
        let days = components.first
        components[0] = components[1]
        components[1] = days!
        var fullDate = ""
        for component in components {
            fullDate.append(component)
            if component != components.last {
                fullDate.append("/")
            }
        }
        return fullDate
    }
}
