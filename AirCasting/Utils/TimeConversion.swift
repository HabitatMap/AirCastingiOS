// Created by Lunar on 09/09/2021.
//

import Foundation

func is24Hour() -> Bool {
    let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!
    return dateFormat.firstIndex(of: "a") == nil
}

func timeConversion24(time12: String) -> String {
    let dateAsString = time12
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "h:mm a"
    
    let date = df.date(from: dateAsString)
    df.dateFormat = "HH:mm"
    
    let time24 = df.string(from: date!)
    return time24
}
