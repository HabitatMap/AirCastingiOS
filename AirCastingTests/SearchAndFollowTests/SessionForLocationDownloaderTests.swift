// Created by Lunar on 02/08/2022.
//
import XCTest
import Resolver
@testable import AirCasting

class SessionForLocationDownloaderTests: ACTestCase {
    lazy var sut = SessionsForLocationDownloaderDefault()
    let clientSpy = APIClientSpy()
    
    func test_whenRequestingDataFromServer_shouldUseGetMethod() {
        Resolver.test.register { self.clientSpy as APIClient }
        MockedSession.getAnySession(using: sut)
        XCTAssertEqual(clientSpy.request.httpMethod, "GET")
    }
    
    func test_whenCreatingQueryItems_shouldUseSmallQAsKey() {
        Resolver.test.register { self.clientSpy as APIClient }
        MockedSession.getAnySession(using: sut)
        guard let queryItems = URLComponents(string: clientSpy.request.description)?.queryItems else { XCTFail("Problem when trying to get query items from url."); return }
        XCTAssertEqual(queryItems[0].name, "q")
    }
    
    func test_whenCreatingUrl_shouldUseAssertedPath() {
        Resolver.test.register { self.clientSpy as APIClient }
        MockedSession.getAnySession(using: sut)
        guard let url = URLComponents(string: clientSpy.request.description)?.url else { XCTFail("Problem when trying to get url request."); return }
        XCTAssertEqual(url.path, "/api/fixed/active/sessions.json")
    }
    
    // This test is considered as valid one, having in mind that [MapDownloaderUnitSymbol] is tested alongside.
    func test_whenGettingProperUnitSymbolForParticulateMatter_shouldReturn_uqm3() {
        Resolver.test.register { self.clientSpy as APIClient }
        let symbol = sut.getProperUnitSymbol(using: .particulateMatter)
        XCTAssertEqual(symbol, .uqm3)
    }
    
    // This test is considered as valid one, having in mind that [MapDownloaderUnitSymbol] is tested alongside.
    func test_whenGettingProperUnitSymbolForOzone_shouldReturn_ppb() {
        Resolver.test.register { self.clientSpy as APIClient }
        let symbol = sut.getProperUnitSymbol(using: .ozone)
        XCTAssertEqual(symbol, .ppb)
    }
    
    class APIClientSpy: APIClient {
        struct URLSessionCancellable: Cancellable {
            weak var dataTask: URLSessionDataTask?
            
            func cancel() {
                dataTask?.cancel()
            }
        }
        
        var request: URLRequest!
        
        func requestTask(for request: URLRequest, completion: @escaping (Result<(data: Data, response: HTTPURLResponse), Error>, URLRequest) -> Void) -> Cancellable {
            self.request = request
            return URLSessionCancellable()
        }
    }
    
    struct MockedSession {
        let geoSquare: GeoSquare
        let timeFrom: Double
        let timeTo: Double
        let measurementType: MapDownloaderMeasurementType
        let sensor: MapDownloaderSensorType
        
        static func getAnySession(using sut: SessionsForLocationDownloader) {
            let session = MockedSession(geoSquare: .init(north: 20.20,
                                                         south: 20.20,
                                                         east: 20.20,
                                                         west: 20.20),
                                        timeFrom: 20.20,
                                        timeTo: 20.20,
                                        measurementType: .particulateMatter,
                                        sensor: .AB3and2)
            
            sut.getSessions(geoSquare: session.geoSquare,
                            timeFrom: session.timeFrom,
                            timeTo: session.timeTo,
                            measurementType: session.measurementType,
                            sensor: session.sensor,
                            completion: { _ in })
        }
    }
}
