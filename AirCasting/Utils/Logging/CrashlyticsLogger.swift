// Created by Lunar on 04/12/2021.
//

import Foundation
import FirebaseCrashlytics

class CrashlyticsLogger: Logger {
    private let formatter: LogFormatter
    
    init(formatter: LogFormatter) {
        self.formatter = formatter
    }
    
    func log(_ message:  @escaping @autoclosure () -> String, type: LogLevel, file: String, function: String, line: Int) {
        let formattedMessage = formatter.format(message(), type: type, file: file, function: function, line: line)
        Crashlytics.crashlytics().log(formattedMessage)
    }
}
