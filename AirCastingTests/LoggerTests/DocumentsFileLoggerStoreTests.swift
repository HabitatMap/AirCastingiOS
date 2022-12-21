import XCTest
@testable import AirCasting

class DocumentsFileLoggerStoreTests: FileLoggerTestCase {
    private let bufferSize = 25
    
    // MARK: - Opening file
    
    func test_whenOpened_createsLogFile() {
        let sut = createSUT()
        openLogFile(sut)
        assertLogDirContainsFile(logFile.lastPathComponent)
    }
    
    func test_whenOpened_addsAnAircastingHeader() {
        let sut = createSUT()
        let headerText = "AirCasting log started."
        headerProvider.headerText = headerText
        openLogFile(sut)
        XCTAssertTrue(try String(contentsOf: logFile).hasPrefix(headerText))
    }
    
    // MARK: - Writing to a file
    
    func test_onWrite_doesntWriteToFileUntilTheBufferIsFull() { // NOTE: Buffer size is 25.
        let sut = createSUT()
        let file = openLogFile(sut)
        appendLogFile(file, "TEST")
        XCTAssertEqual(readLogsFromFile(), [])
    }
    
    func test_onWrite_writesIn25Chunks() { // NOTE: Buffer size is 25.
        let sut = createSUT()
        let file = openLogFile(sut)
        (0..<bufferSize+5).forEach { _ in appendLogFile(file, "TEST") }
        XCTAssertEqual(readLogsFromFile().count, bufferSize)
        XCTAssertEqual(readLogsFromFile(), [String].init(repeating: "TEST", count: bufferSize))
        (0..<bufferSize-5).forEach { _ in appendLogFile(file, "TEST") }
        XCTAssertEqual(readLogsFromFile().count, 2*bufferSize)
        XCTAssertEqual(readLogsFromFile(), [String].init(repeating: "TEST", count: bufferSize*2))
    }
    
    // MARK: - Closing file
    
    func test_onHandleRelease_flushesBuffer() {
        let sut = createSUT()
        autoreleasepool {
            let file = openLogFile(sut)
            appendLogFile(file, "TEST")
        }
        XCTAssertEqual(readLogsFromFile(), ["TEST"])
    }
    
    func test_onAppTermination_flushesBuffer() {
        let sut = createSUT()
        let file = openLogFile(sut)
        appendLogFile(file, "TEST")
        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
        XCTAssertEqual(readLogsFromFile(), ["TEST"])
    }
    
    // MARK: Resetting file
    
    func test_resetFile_clearsFileContent() {
        let sut = createSUT()
        let file = openLogFile(sut)
        (0..<bufferSize).forEach { _ in appendLogFile(file, "BEFORE_RESET") }
        resetLogFile(sut)
        XCTAssertEqual(readLogsFromFile(), [])
    }
    
    func test_whenFileWasReset_itStillCanBeWrittenTo() {
        let sut = createSUT()
        let file = openLogFile(sut)
        (0..<bufferSize).forEach { _ in appendLogFile(file, "BEFORE_RESET") }
        resetLogFile(sut)
        (0..<bufferSize).forEach { _ in appendLogFile(file, "AFTER_RESET") }
        XCTAssertEqual(readLogsFromFile(), [String].init(repeating: "AFTER_RESET", count: bufferSize))
        assertLogDirContainsFileCount(1)
    }
    
    // MARK: - Trimming
    
    func test_whenReachesMaxCount_trimsBeginningOfLogfile() {
        // Note: this happens only during actual file sizes, so the test needs to take that into account
        // (file saves happen when buffer limit is reached)
        let overflow = 75
        let maxLogs = 50
        let sut = createSUT(maxLogs: UInt(maxLogs))
        let file = openLogFile(sut)
        (0..<maxLogs + overflow).forEach { appendLogFile(file, "\($0)") } // Add more logs than permittable
        let expectedLogs = (0..<maxLogs).map { "\(overflow + $0)" }
        XCTAssertEqual(readLogsFromFile(), expectedLogs)
    }
    
    func test_whenReachesMaxCount_andOverflowThresholdIsNotReached_doesntTrim() {
        // Note: this happens only during actual file sizes, so the test needs to take that into account
        // (file saves happen when buffer limit is reached)
        let overflow = 30
        let maxLogs = 100
        let sut = createSUT(maxLogs: UInt(maxLogs), overflowThreshold: 31)
        let file = openLogFile(sut)
        (0..<maxLogs + overflow).forEach { appendLogFile(file, "\($0)") } // Add more logs than permittable
        let logsStillInBuffer = (overflow - bufferSize)
        let expectedLogs = (0..<maxLogs + overflow  - logsStillInBuffer).map { "\($0)" }
        XCTAssertEqual(readLogsFromFile(), expectedLogs)
    }
    
    func test_whenReachesMaxCount_andExceedsOverflowThreshold_trimsBeginning() {
        // Note: this happens only during actual file sizes, so the test needs to take that into account
        // (file saves happen when buffer limit is reached)
        let overflow = 30
        let maxLogs = 100
        let sut = createSUT(maxLogs: UInt(maxLogs), overflowThreshold: 20)
        let file = openLogFile(sut)
        (0..<maxLogs + overflow).forEach { appendLogFile(file, "\($0)") } // Add more logs than permittable
        let logsStillInBuffer = (overflow - bufferSize)
        let expectedLogs = (0..<maxLogs).map { "\(overflow - logsStillInBuffer + $0)" }
        XCTAssertEqual(readLogsFromFile(), expectedLogs)
    }
    
    // MARK: - Errors
    
    func test_whenOpeningWhenActiveHandle_returnsEmptyHandle() {
        let sut = createSUT()
        let firstHandle = openLogFile(sut)
        let secondHandle = openLogFile(sut)
        XCTAssertTrue(firstHandle is DocumentsFileLoggerStore.LogHandle)
        XCTAssertTrue(secondHandle is DocumentsFileLoggerStore.EmptyFileLoggerFileHandle)
    }
    
    // MARK: - Private helpers
    
    private func createSUT(maxLogs: UInt = 1000, overflowThreshold: UInt = 0) -> DocumentsFileLoggerStore {
        return DocumentsFileLoggerStore(logDirectory: logDir.lastPathComponent, logFilename: logFile.lastPathComponent, maxLogs: maxLogs, overflowThreshold: overflowThreshold, headerProvider: headerProvider)
    }
    
    @discardableResult
    private func openLogFile(_ sut: DocumentsFileLoggerStore, file: StaticString = #file, line: UInt = #line) -> FileLoggerFileHandle {
        sut.openOrCreateLogFile()
    }
    
    private func appendLogFile(_ handle: FileLoggerFileHandle, _ string: String, file: StaticString = #file, line: UInt = #line) {
        do {
            try handle.appendFile(with: string)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
    
    private func resetLogFile(_ sut: DocumentsFileLoggerStore, file: StaticString = #file, line: UInt = #line) {
        do {
            return try sut.resetFile()
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}

struct FileLoggerFileHandleDummy: FileLoggerFileHandle {
    func appendFile(with: String) throws { }
}
