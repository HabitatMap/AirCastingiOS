import Foundation
@testable import AirCasting

class LoggerSpy: Logger {
    struct CallHistoryItem: Equatable {
        let message: String
        let level: LogLevel
    }
    
    var logged: [CallHistoryItem] = []
    
    func log(_ message: @autoclosure @escaping () -> String, type: LogLevel, file: String, function: String, line: Int) {
        logged.append(.init(message: message(), level: type))
    }
}
