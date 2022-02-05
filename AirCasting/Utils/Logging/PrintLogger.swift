// Created by Lunar on 05/02/2022.
//

import Foundation

// swiftlint:disable print_using
public final class PrintLogger: Logger {
    let formatter: LogFormatter

    public init(formatter: LogFormatter = SimpleLogFormatter()) {
        self.formatter = formatter
    }

    public func log(_ message: @escaping  @autoclosure () -> String, type: LogLevel, file: String = #fileID, function: String = #function, line: Int = #line) {
        print(formatter.format(message(), type: type, file: file, function: function, line: line))
    }
}
// swiftlint:enable print_using
