// Created by Lunar on 19/11/2021.
//

import XCTest
@testable import AirCasting

fileprivate extension SDCardSessionType {
    var name: String {
        switch self {
        case .mobile: return "MOBILE"
        case .fixed: return "FIXED"
        case .cellular: return "CELLULAR"
        }
    }
}

class SDSyncFileWritingServiceTests: ACTestCase {
    let service = SDSyncFileWritingService(bufferThreshold: 3)
    let measurementsCountSession1 = 100
    let measurementsCountSession2 = 80
    let uuid = "123"
    let uuid2 = "456"
    
    override func setUp() {
        super.setUp()
        SDCardSessionType.allCases.forEach { type in
            for i in 0...measurementsCountSession1 {
                let line = createFileLine(uuid: uuid + type.name, lineNumber: i, sessionType: type)
                service.writeToFile(data: line, sessionType: type)
            }
            
            for i in 0...measurementsCountSession2 {
                let line = createFileLine(uuid: uuid2 + type.name, lineNumber: i, sessionType: type)
                service.writeToFile(data: line, sessionType: type)
            }
        }
    }
    
    func test_createsMobileAndFixedDirectories() {
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
    }
    
    func test_savesSessionsDataToSeparateFiles() throws {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
        
        try SDCardSessionType.allCases.forEach { type in
            let session1File = documents.appendingPathComponent(type == .mobile ? "mobile" : "fixed").appendingPathComponent(uuid + type.name)
            let session2File = documents.appendingPathComponent(type == .mobile ? "mobile" : "fixed").appendingPathComponent(uuid2 + type.name)
            XCTAssertTrue(FileManager.default.fileExists(atPath: session1File.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: session2File.path))
            
            let session1FileContent = try XCTUnwrap(try? String(contentsOf: session1File))
            let expectedSession1FileContent = (0...measurementsCountSession1).map {
                createFileLine(uuid: uuid + type.name, lineNumber: $0, sessionType: type)
            }.joined(separator: "\n")
            
            XCTAssertEqual(session1FileContent.trimmingCharacters(in: .newlines), expectedSession1FileContent)
            
            let session2FileContent = try XCTUnwrap(try? String(contentsOf: session2File))
            let expectedSession2FileContent = (0...measurementsCountSession2).map {
                createFileLine(uuid: uuid2 + type.name, lineNumber: $0, sessionType: type)
            }.joined(separator: "\n")
            
            XCTAssertEqual(session2FileContent.trimmingCharacters(in: .newlines), expectedSession2FileContent)
        }
    }
    
    private func createFileLine(uuid: String, lineNumber: Int, sessionType: SDCardSessionType) -> String {
        "\(lineNumber),\(uuid),1,1,1,1,1,1,1,1,1,1,\(lineNumber)_\(sessionType.name)"
    }
}
