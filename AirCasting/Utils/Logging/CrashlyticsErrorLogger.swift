// Created by Lunar on 24/08/2022.
//

import Foundation
import FirebaseCrashlytics

class CrashlyticsErrorLogger: Logger {
    private let crashlyticsDateFormatter = DateFormatter(format: "MM-dd-y HH:mm:ss.SSS", timezone: .utc)
    
    func log(_ message:  @escaping @autoclosure () -> String, type: LogLevel, file: String, function: String, line: Int) {
        Crashlytics.crashlytics().record(error: logToError(message(), time: DateBuilder.getRawDate(), location: "\(file)/\(function)"))
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
