import XCTest
@testable import AirCasting

class TextFileTrimmerTests: FileLoggerTestCase {
    
    // MARK: - Functionality
    
    func test_whenNoOffset_andNoTrim() {
        let sut = createSUT(fileLines: ["First", "Second", "Third"])
        trim(sut, direction: .beginning(offset: 0), trimCount: 0)
        XCTAssertEqual(rawLogfileContent(), "First\nSecond\nThird")
    }
    
    func test_whenNoOffset_andTrimmed() {
        let sut = createSUT(fileLines: ["First", "Second", "Third"])
        trim(sut, direction: .beginning(offset: 0), trimCount: 1)
        XCTAssertEqual(rawLogfileContent(), "Second\nThird")
    }
    
    func test_multipleLinesOffset_andTrimmed() {
        let sut = createSUT(fileLines: ["First", "Second", "Third", "Fourth", "Fifth"])
        trim(sut, direction: .beginning(offset: 2), trimCount: 2)
        XCTAssertEqual(rawLogfileContent(), "First\nSecond\nFifth")
    }
    
    func test_whenOffset_andTrimmed() {
        let sut = createSUT(fileLines: ["First", "Second", "Third"])
        trim(sut, direction: .beginning(offset: 1), trimCount: 1)
        XCTAssertEqual(rawLogfileContent(), "First\nThird")
    }
    
    // MARK: - File handling
    
    func test_whenFileAlreadyExist_overridesIt() {
        try! FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: logFile.path, contents: "ASD".data(using: .utf8)!, attributes: nil)
        
        let sut = createSUT(fileLines: ["First"])
        trim(sut, direction: .beginning(offset: 0), trimCount: 0)
        XCTAssertEqual(rawLogfileContent(), "First")
    }
    
    func test_removesTempFilesCorrectly() {
        let sut = createSUT(fileLines: ["First"])
        trim(sut, direction: .beginning(offset: 0), trimCount: 0)
        assertLogDirContainsFileCount(1)
    }
    
    // MARK: - Private helpers
    
    private func createSUT(fileLines: [String]) -> TextFileTrimmer {
        let reader = FileLineReaderStub()
        reader.progress = fileLines.map { .line($0) } + [.endOfFile]
        return TextFileTrimmer(reader: reader)
    }
    
    private func trim(_ sut: TextFileTrimmer, direction: TextFileTrimmer.Direction, trimCount: UInt, file: StaticString = #file, line: UInt = #line) {
        do {
            try sut.trim(at: logFile, direction: direction, trimCount: trimCount)
        } catch {
            XCTFail("Unexpected trim function failure! \(error)", file: file, line: line)
        }
    }
}

class FileLineReaderStub: FileLineReader {
    var progress: [FileLineReaderProgress] = []
    
    func readLines(of: URL, progress: (FileLineReaderProgress) -> Void) throws {
        self.progress.forEach {
            progress($0)
        }
    }
    
    func readLastLine(of fileURL: URL) throws -> String {
        ""
    }
}
