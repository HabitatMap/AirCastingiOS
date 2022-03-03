// Created by Lunar on 05/02/2022.
//

import Foundation

// swiftlint:disable print_using
/// A logger that will use `print` statements as output. Only eligible for debug builds connected to the debugger (note that `print` logs are not seen in the Console.app
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
