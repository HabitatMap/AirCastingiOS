// Created by Lunar on 19/11/2021.
//

import XCTest
@testable import AirCasting

class SDSyncFileWritingServiceTests: ACTestCase {
    
    func test_integration() {
        let threshold = 3
        let service = SDSyncFileWritingService(bufferThreshold: threshold)
        let testWritesCount = 110
        let uuid = "123"
        let uuid2 = "456"
        for i in 0...testWritesCount {
            service.writeToFile(data: "1,\(i < testWritesCount/2 ? uuid : uuid2),1,1,1,1,1,1,1,1,1,1,\(i)_MOBILE", sessionType: .mobile)
        }
        
        for i in 0...testWritesCount {
            service.writeToFile(data: "1,\(i < testWritesCount/2 ? uuid : uuid2)23,1,1,1,1,1,1,1,1,1,1,\(i)_FIXED", sessionType: .fixed)
        }
        
        for i in 0...testWritesCount {
            service.writeToFile(data: "1,\(i < testWritesCount/2 ? uuid : uuid2),1,1,1,1,1,1,1,1,1,1,\(i)_CELLULAR", sessionType: .cellular)
        }
        
        let directories = service.finishAndSave()
        
        let documents = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
        let mobileFileURL = documents.appendingPathComponent("mobile")
        let fixedFileURL = documents.appendingPathComponent("fixed")
        XCTAssertTrue(FileManager.default.fileExists(atPath: mobileFileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixedFileURL.path))
        XCTAssertEqual(directories.first?.0, mobileFileURL)
        XCTAssertEqual(directories.last?.0, fixedFileURL)
        XCTAssertEqual(directories.first?.1, .mobile)
        XCTAssertEqual(directories.last?.1, .fixed)
        
        let session1MobileFile = mobileFileURL.appendingPathComponent(uuid)
        let session2MobileFile = mobileFileURL.appendingPathComponent(uuid2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: session1MobileFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: session2MobileFile.path))
        
        let session1FixedFile = fixedFileURL.appendingPathComponent(uuid + "23")
        let session2FixedFile = fixedFileURL.appendingPathComponent(uuid2 + "23")
        XCTAssertTrue(FileManager.default.fileExists(atPath: session1FixedFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: session2FixedFile.path))
        
        let session1CellularFile = fixedFileURL.appendingPathComponent(uuid)
        let session2CellularFile = fixedFileURL.appendingPathComponent(uuid2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: session1CellularFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: session2CellularFile.path))
        
        let session1MobileFileContent = try! String(contentsOf: session1MobileFile)
//        let mobileFileContent = try! String(contentsOf: mobileFileURL)
        
        let expectedFixedFileContent = (0...testWritesCount).map {
            "\($0)_CELLULAR\n\($0)_FIXED"
        }.joined(separator: "\n")
        
        let expectedMobileFileContent = (0..<testWritesCount/2).map {
            "1,\(uuid),1,1,1,1,1,1,1,1,1,1,\($0)_MOBILE"
        }.joined(separator: "\n")
        
//        XCTAssertEqual(fixedFileContent.trimmingCharacters(in: .newlines), expectedFixedFileContent)
        XCTAssertEqual(session1MobileFileContent.trimmingCharacters(in: .newlines), expectedMobileFileContent)
    }
}
