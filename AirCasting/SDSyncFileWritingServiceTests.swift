// Created by Lunar on 19/11/2021.
//

import XCTest
@testable import AirCasting

class SDSyncFileWritingServiceTests: XCTestCase {
    
    func test_integration() {
        let threshold = 3
        let service = SDSyncFileWritingService(bufferThreshold: threshold)
        let testWritesCount = 110
        for i in 0...testWritesCount {
            service.writeToFile(data: "\(i)_MOBILE", sessionType: .mobile)
            service.writeToFile(data: "\(i)_CELLULAR", sessionType: .cellular)
            service.writeToFile(data: "\(i)_FIXED", sessionType: .fixed)
        }
        service.finishAndSave()
        
        let documents = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
        let mobileFileURL = documents.appendingPathComponent("mobile.csv")
        let fixedFileURL = documents.appendingPathComponent("fixed.csv")
        XCTAssertTrue(FileManager.default.fileExists(atPath: mobileFileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixedFileURL.path))
        
        let fixedFileContent = try! String(contentsOf: fixedFileURL)
        let mobileFileContent = try! String(contentsOf: mobileFileURL)
        
        let expectedFixedFileContent = (0...testWritesCount).map {
            "\($0)_CELLULAR\n\($0)_FIXED"
        }.joined(separator: "\n")
        
        let expectedMobileFileContent = (0...testWritesCount).map {
            "\($0)_MOBILE"
        }.joined(separator: "\n")
        
        XCTAssertEqual(fixedFileContent.trimmingCharacters(in: .newlines), expectedFixedFileContent)
        XCTAssertEqual(mobileFileContent.trimmingCharacters(in: .newlines), expectedMobileFileContent)
    }
}
