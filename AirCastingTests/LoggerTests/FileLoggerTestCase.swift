import XCTest

class FileLoggerTestCase: XCTestCase {
    lazy var logDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent("log_dir", isDirectory: true)
    lazy var logFile = logDir.appendingPathComponent("logs.txt")
    
    override func setUp() {
        super.setUp()
        if FileManager.default.fileExists(atPath: logFile.path) {
            try! FileManager.default.removeItem(at: logFile)
            try! FileManager.default.removeItem(at: logDir)
        } else if FileManager.default.fileExists(atPath: logDir.path) {
            try! FileManager.default.removeItem(at: logDir)
        }
    }
    
    func rawLogfileContent(file: StaticString = #file, line: UInt = #line) -> String {
        do {
            return try String(contentsOf: logFile)
        } catch {
            XCTFail("Error while reading contents of \(logFile.path): \(error)", file: file, line: line)
            return ""
        }
    }
    
    func readLogsFromFile(file: StaticString = #file, line: UInt = #line) -> [String] {
        do {
            return try Array(String(contentsOf: logFile).components(separatedBy: .newlines).dropFirst())
        } catch {
            XCTFail("Error while reading contents of \(logFile.path): \(error)", file: file, line: line)
            return []
        }
    }
    
    func assertLogDirContainsFile(_ name: String, file: StaticString = #file, line: UInt = #line) {
        guard FileManager.default.fileExists(atPath: logDir.path) else {
            XCTFail("There is no directory at \(logDir.path)", file: file, line: line)
            return
        }
        do {
            guard try FileManager.default.contentsOfDirectory(atPath: logDir.path).contains(name) else {
                XCTFail("No file named \(name) found at \(logDir.path)", file: file, line: line)
                return
            }
        } catch {
            XCTFail("Error while reading contents of \(logDir.path): \(error)", file: file, line: line)
        }
    }
    
    func assertLogDirContainsFileCount(_ expectedCount: UInt, file: StaticString = #file, line: UInt = #line) {
        guard FileManager.default.fileExists(atPath: logDir.path) else {
            XCTFail("There is no directory at \(logDir.path)", file: file, line: line)
            return
        }
        do {
            let dirCount = try FileManager.default.contentsOfDirectory(atPath: logDir.path).count
            guard dirCount == expectedCount else {
                XCTFail("Log dir contains \(dirCount) file(s), not \(expectedCount)", file: file, line: line)
                return
            }
        } catch {
            XCTFail("Error while reading contents of \(logDir.path): \(error)", file: file, line: line)
        }
    }
}
