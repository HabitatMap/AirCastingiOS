////
////  URLValidationTests.swift
////  URLValidationTests
////
//// Created by Lunar on 25/06/2021.
////
//
//import XCTest
//@testable import AirCasting
//
//class URLBuilderTests: XCTestCase {
//    private let builder = BackendURLBuilder()
//    static private let validURL = "https://superstronka.com/"
//    static private let validPort = "23"
//    private typealias ErrorType = BackendURLBuilder.ValidationError
//    
//    // MARK: - URL Validation
//    
//    func test_whenURLIsInvalid_itThowsCorrectError() {
//        let invalidBackendURL = "IamInvalid"
//        XCTAssertThrowsError(try runBuilder(url: invalidBackendURL))
//        do {
//            try runBuilder(url: invalidBackendURL)
//        } catch {
//            XCTAssertEqual(error as? ErrorType, .invalidURL)
//        }
//    }
//    
//    func test_whenURLIsValid_itDoesntThrowError() {
//        let validBackendURL = "https://superstronka.com/"
//        XCTAssertNoThrow(try runBuilder(url: validBackendURL))
//    }
//    
//    func test_whenNoDotInHost_itThrowsCorrectError() {
//        let noDotURL = "https://superstronka"
//        XCTAssertThrowsError(try runBuilder(url: noDotURL))
//        do {
//            try runBuilder(url: noDotURL)
//        } catch {
//            XCTAssertEqual(error as? ErrorType, .invalidURL)
//        }
//    }
//    
//    func test_nothingAfterDotURL_itThrowsCorrectError() {
//        let dotOnlyURL = "https://superstronka."
//        XCTAssertThrowsError(try runBuilder(url: dotOnlyURL))
//        do {
//            try runBuilder(url: dotOnlyURL)
//        } catch {
//            XCTAssertEqual(error as? ErrorType, .invalidURL)
//        }
//    }
//    
//    func test_whenNoHTTPGiven_itDoesntThrowError() {
//        let validBackendURL = "superstronka.com"
//        XCTAssertNoThrow(try runBuilder(url: validBackendURL))
//    }
//    
//    func test_whenPathIsPresent_itDoesntThrowError() {
//        let validBackendURL = "superstronka.com/some/path"
//        XCTAssertNoThrow(try runBuilder(url: validBackendURL))
//    }
//    
//    // MARK: - Port Validation
//    
//    func test_whenPortIsNotANumber_itThrowsCorrectError() {
//        let invalidPort = "A1"
//        XCTAssertThrowsError(try runBuilder(port: invalidPort))
//        do {
//            try runBuilder(port: invalidPort)
//        } catch {
//            XCTAssertEqual(error as? ErrorType, .invalidPort)
//        }
//    }
//    
//    func test_whenOnlyPortIsPresent_itThrowsCorrectError() {
//        let validPort = "21"
//        XCTAssertThrowsError(try runBuilder(url: "", port: validPort))
//        do {
//            try runBuilder(url: "", port: validPort)
//        } catch {
//            XCTAssertEqual(error as? ErrorType, .noURL)
//        }
//    }
//    
//    func test_whenPortIsANumber_itDoesntThrowError() {
//        let validPort = "123"
//        XCTAssertNoThrow(try runBuilder(port: validPort))
//    }
//    
//    func test_whenPortIsEmpty_itDoesntThrowError() {
//        let emptyPort = ""
//        XCTAssertNoThrow(try runBuilder(port: emptyPort))
//    }
//    
//    // MARK: - URL Creation
//    
//    func test_whenURLIsEmpty_itReturnsNil() throws {
//        let url = try runBuilder(url: "", port: "")
//        XCTAssertNil(url)
//    }
//    
//    func test_whenNoPortPresent_createsProperURL() throws {
//        let url = try runBuilder(url: "www.fajnie.pl", port: "")
//        XCTAssertEqual(url?.absoluteString, "http://www.fajnie.pl")
//    }
//    
//    func test_whenPortIsPresent_createsProperURL() throws {
//        let url = try runBuilder(url: "www.fajnie.pl", port: "420")
//        XCTAssertEqual(url?.absoluteString, "http://www.fajnie.pl:420")
//    }
//    
//    // MARK: - Private Helpers
//    
//    @discardableResult
//    private func runBuilder(url: String = URLBuilderTests.validURL, port: String = URLBuilderTests.validPort) throws -> URL? {
//        try builder.createURL(url: url, port: port)
//    }
//}
