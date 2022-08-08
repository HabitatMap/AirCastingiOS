// Created by Lunar on 02/08/2022.
//
import XCTest
import Resolver
@testable import AirCasting

class SessionForLocationDownloaderTests: ACTestCase {
    lazy var sut = SessionsForLocationDownloaderDefault()
    let clientSpy = APIClientMock()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.clientSpy as APIClient }
    }
    
    func test_requestingDataFromServer_usesGetMethod() {
        clientSpy.returning((data: Data.default, response: .success()))
        requestMockSession()
        XCTAssert(clientSpy.callHistory.count == 1, "Number of requests should be equal to one, as only once call was requested.")
        XCTAssertEqual(clientSpy.callHistory.first!.httpMethod, "GET")
    }
    
    func test_creatingQueryItems_usesSmallQAsParameterName() throws {
        clientSpy.returning((data: Data.default, response: .success()))
        requestMockSession()
        XCTAssert(clientSpy.callHistory.count == 1, "Number of requests should be equal to one, as only once call was requested.")
        let firstQueryItems = try XCTUnwrap(URLComponents(string: clientSpy.callHistory.first!.description)?.queryItems?.first, "Problem when trying to get query items from url.")
        XCTAssertEqual(firstQueryItems.name, "q")
    }
    
    func test_creatingUrl_usesCorrectPath() throws {
        clientSpy.returning((data: Data.default, response: .success()))
        requestMockSession()
        XCTAssert(clientSpy.callHistory.count == 1, "Number of requests should be equal to one, as only once call was requested.")
        let url = try XCTUnwrap(URLComponents(string: clientSpy.callHistory.first!.description)?.url, "Problem when trying to get url request.")
        XCTAssertEqual(url.path, "/api/fixed/active/sessions.json")
    }
    
    // This test is considered as valid one, having in mind that [MapDownloaderUnitSymbol] is tested in a separate unit test.
    func test_gettingProperUnitSymbolForParticulateMatter_returns_uqm3() {
        let symbol = sut.getProperUnitSymbol(using: .particulateMatter)
        XCTAssertEqual(symbol, .uqm3)
    }
    
    // This test is considered as valid one, having in mind that [MapDownloaderUnitSymbol] is tested in a separate unit test.
    func test_gettingProperUnitSymbolForOzone_returns_ppb() {
        let symbol = sut.getProperUnitSymbol(using: .ozone)
        XCTAssertEqual(symbol, .ppb)
    }
    
    private func requestMockSession() {
        let mock = MockedSession.any
        sut.getSessions(geoSquare: mock.geoSquare,
                        timeFrom: mock.timeFrom,
                        timeTo: mock.timeTo,
                        measurementType: mock.measurementType,
                        sensor: mock.sensor,
                        completion: { _ in })
    }
    
    struct MockedSession {
        let geoSquare: GeoSquare
        let timeFrom: Double
        let timeTo: Double
        let measurementType: MapDownloaderMeasurementType
        let sensor: MapDownloaderSensorType
        
        static var any: Self {
            MockedSession(geoSquare: .init(north: 20.20,
                                           south: 20.20,
                                           east: 20.20,
                                           west: 20.20),
                          timeFrom: 20.20,
                          timeTo: 20.20,
                          measurementType: .particulateMatter,
                          sensor: .AB3and2)
        }
    }
}
