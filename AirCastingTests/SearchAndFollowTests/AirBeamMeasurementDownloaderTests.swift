// Created by Lunar on 03/08/2022.
//
import XCTest
import Resolver
@testable import AirCasting

class AirBeamMeasurementDownloaderTests: ACTestCase {
    lazy var sut = AirBeamMeasurementsDownloaderDefault()
    let clientSpy = APIClientSpy()
    
    func test_whenRequestingDataFromServer_shouldUseAssertedPath() {
        Resolver.test.register { self.clientSpy as APIClient }
        sut.downloadStreams(with: Int.default, completion: { _ in })
        guard let url = URLComponents(string: clientSpy.request.description)?.url else { XCTFail("Problem when trying to get url."); return }
        XCTAssertEqual(url.path, "/api/fixed/sessions/\(Int.default)/streams.json")
    }
    
    func test_whenRequestingDataFromServer_shouldUseGetMethod() {
        Resolver.test.register { self.clientSpy as APIClient }
        sut.downloadStreams(with: Int.default, completion: { _ in })
        XCTAssertEqual(clientSpy.request.httpMethod, "GET")
    }
    
    func test_whenRequestingDataFromServer_shouldUseGivenSesionUUIDinsidePath() {
        Resolver.test.register { self.clientSpy as APIClient }
        let sessionUUID = 123456-789
        sut.downloadStreams(with: sessionUUID, completion: { _ in })
        guard let url = URLComponents(string: clientSpy.request.description)?.url else { XCTFail("Problem when trying to get url."); return }
        XCTAssertEqual(url.path, "/api/fixed/sessions/\(sessionUUID)/streams.json")
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
}
