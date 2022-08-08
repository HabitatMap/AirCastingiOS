// Created by Lunar on 03/08/2022.
//
import XCTest
import Resolver
@testable import AirCasting

class AirBeamMeasurementDownloaderTests: ACTestCase {
    lazy var sut = AirBeamMeasurementsDownloaderDefault()
    let clientSpy = APIClientMock()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.clientSpy as APIClient }
        clientSpy.returning((data: Data.default, response: .success()))
    }
    
    func test_requestingDataFromServer_usesCorrectPath() throws {
        sut.downloadStreams(with: Int.default, completion: { _ in })
        
        XCTAssert(clientSpy.callHistory.count == 1, "Number of requests should be equal to one, as only once call was requested.")
        let url = try XCTUnwrap(URLComponents(string: clientSpy.callHistory.first!.description)?.url, "Problem when trying to get url.")
        XCTAssertEqual(url.path, "/api/fixed/sessions/\(Int.default)/streams.json")
    }
    
    func test_requestingDataFromServer_usesGetMethod() {
        sut.downloadStreams(with: Int.default, completion: { _ in })
        
        XCTAssert(clientSpy.callHistory.count == 1, "Number of requests should be equal to one, as only once call was requested.")
        XCTAssertEqual(clientSpy.callHistory.first!.httpMethod, "GET")
    }
    
    func test_requestingDataFromServer_usesGivenSesionUUID() throws {
        let sessionUUID = 123456-789
        sut.downloadStreams(with: sessionUUID, completion: { _ in })
        
        XCTAssert(clientSpy.callHistory.count == 1, "Number of requests should be equal to one, as only once call was requested.")
        let url = try XCTUnwrap(URLComponents(string: clientSpy.callHistory.first!.description)?.url, "Problem when trying to get url.")
        XCTAssertEqual(url.path, "/api/fixed/sessions/\(sessionUUID)/streams.json")
    }
    
    func test_requestingDataFromServer_usesCorrectNameForLimit() throws {
        sut.downloadStreams(with: Int.default, completion: { _ in })
        
        XCTAssert(clientSpy.callHistory.count == 1, "Number of requests should be equal to one, as only once call was requested.")
        let queryItem = try XCTUnwrap(URLComponents(string: clientSpy.callHistory.first!.description)?.queryItems, "Problem when trying to get url.")
        XCTAssert(queryItem.contains(where: { $0.name == "measurements_limit" }))
    }
    
    func test_requestingDataFromServer_givesCorrectMeasurementNumber() throws {
        sut.downloadStreams(with: Int.default, completion: { _ in })
        
        XCTAssert(clientSpy.callHistory.count == 1, "Number of requests should be equal to one, as only once call was requested.")
        let queryItem = try XCTUnwrap(URLComponents(string: clientSpy.callHistory.first!.description)?.queryItems, "Problem when trying to get url.")
        let measurementsValue = try XCTUnwrap(queryItem.first(where: { $0.name == "measurements_limit" }))
        XCTAssertEqual(measurementsValue.value, "1440")
    }
}
