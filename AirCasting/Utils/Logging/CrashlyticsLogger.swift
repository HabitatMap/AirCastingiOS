// Created by Lunar on 04/12/2021.
//

import Foundation
import FirebaseCrashlytics
import Resolver

class CrashlyticsLogger: Logger {
    @Injected private var formatter: LogFormatter
    private let crashlyticsDateFormatter = DateFormatter(format: "MM-dd-y HH:mm:ss.SSS", timezone: .utc)
    
    func log(_ message:  @escaping @autoclosure () -> String, type: LogLevel, file: String, function: String, line: Int) {
        let formattedMessage = formatter.format(message(), type: type, file: file, function: function, line: line)
        Crashlytics.crashlytics().log(formattedMessage)
        if case .error = type {
            Crashlytics.crashlytics().record(error: logToError(message(), time: DateBuilder.getRawDate(), location: "\(file)/\(function)"))
        }
    }
    
    private func logToError(_ log: String, time: Date, location: String) -> Error {
        let userInfo: [String: String] = [
            "message": log,
            "time": crashlyticsDateFormatter.string(from: time)
        ]

        return NSError(
                domain: location,
                code: 0,
                userInfo: userInfo
        )
    }
}
