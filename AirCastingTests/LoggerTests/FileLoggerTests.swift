import XCTest
import Resolver
@testable import AirCasting

class FileLoggerTests: ACTestCase {
    
    func test_onInit_opensLogFile() {
        do {
            let (_, storeSpy, _) = try makeSUT()
            XCTAssertEqual(storeSpy.logFileOpenedTimes, 1)
        } catch {
            XCTFail("Couldnt create SUT: \(error)")
        }
    }
    
    func test_onLog_appendsFileWithLog() {
        do {
            let (sut, storeSpy, _) = try makeSUT()
            sut.log("test", type: .info)
            XCTAssertEqual(storeSpy.recordedWrites, ["test"])
        } catch {
            XCTFail("Couldnt create SUT: \(error)")
        }
    }
    
    func test_onLog_passesMessageThruFormatter() {
        do {
            let (sut, storeSpy, formatterMock) = try makeSUT()
            let unformattedMessage = "test"; let messageLevel = LogLevel.info
            let formattedMessage = "Formatted test"
            formatterMock.returnValue = formattedMessage
            
            sut.log(unformattedMessage, type: messageLevel)
            XCTAssertEqual(storeSpy.recordedWrites, [formattedMessage])
            XCTAssertEqual(formatterMock.formattedMessages, [.init(message: unformattedMessage, type: messageLevel)])
        } catch {
            XCTFail("Couldnt create SUT: \(error)")
        }
    }
    
    // MARK: - Private helpers
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) throws -> (FileLogger, FileLoggerStoreSpy, LogFormatterMock) {
        let storeSpy = FileLoggerStoreSpy()
        let formatterMock = LogFormatterMock()
        Resolver.register { storeSpy as FileLoggerStore }
        Resolver.register { formatterMock as LogFormatter }
        return (FileLogger(), storeSpy, formatterMock)
    }
}

class FileLoggerStoreSpy: FileLoggerStore {
    private var fileHandleSpy: FileHandleSpy!
    var recordedWrites: [String] { fileHandleSpy.recordedStrings }
    var logFileOpenedTimes: Int = 0

    private class FileHandleSpy: FileLoggerFileHandle {
        private(set) var recordedStrings: [String] = []

        func appendFile(with text: String) throws {
            recordedStrings.append(text)
        }
    }

    func openOrCreateLogFile() -> FileLoggerFileHandle {
        logFileOpenedTimes += 1
        fileHandleSpy = .init()
        return fileHandleSpy
    }
}

class LogFormatterMock: LogFormatter {
    struct CallHistoryItem: Equatable {
        let message: String
        let type: LogLevel
    }
    
    var returnValue: String?
    var formattedMessages: [CallHistoryItem] = []
    
    func format(_ message: String, type: LogLevel, file: String, function: String, line: Int) -> String {
        formattedMessages.append(.init(message: message, type: type))
        return returnValue ?? message
    }
}
