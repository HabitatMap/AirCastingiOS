// Created by Lunar on 26/11/2021.
//

@testable import AirCasting
import XCTest

class LineFileReaderTests: XCTestCase {
    let sut: FileLineReader = DefaultFileLineReader()
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("LineFileReaderTests")
    
    func test_integration() {
        let lineCount = 10
        let progressItemsCount = lineCount + 1
        createFile(lineCount: lineCount)
        
        var progressItems: [FileLineReaderProgress] = []
        try! sut.readLines(of: fileURL, progress: { progressItems.append($0) })
        
        guard progressItems.count == progressItemsCount else {
            XCTFail("Expected to have \(progressItemsCount) progress items, had \(progressItems.count)")
            return
        }
        
        (0..<progressItemsCount).forEach {
            let isLastElement = ($0 == progressItemsCount - 1)
            XCTAssertEqual(progressItems[$0], isLastElement ? .endOfFile : .line("Line number \($0)"))
        }
    }
    
    func test_throwsWhenNoFile() {
        XCTAssertThrowsError(try sut.readLines(of: URL(fileURLWithPath: "/chyba/ty.bat"), progress: { _ in }))
    }
    
    private func createFile(lineCount: Int) {
        let content = (0..<lineCount).map { "Line number \($0)" }.joined(separator: "\n")
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: fileURL)
    }
}
