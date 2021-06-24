// Created by Lunar on 19/06/2021.
//

import XCTest
import Combine
import Gzip
@testable import AirCasting

class SyncUpstreamServiceTests: XCTestCase {
    let client = APIClientMock()
    let auth = RequestAuthorizationServiceMock()
    let responseValidator = HTTPResponseValidatorMock()
    lazy var service = SessionUploadService(client: client, authorization: auth, responseValidator: responseValidator)
    private var cancellables: [AnyCancellable] = []
    
    func test_callsEndponitCorrectly() {
        setupWithCorrectDataReturned()
        let exp = expectation(description: "Will call correct endpoint")
        service
            .upload(session: .mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTAssertEqual(self.client.callHistory.count, 1)
                let request = self.client.callHistory.first!
                XCTAssertEqual(request.url?.absoluteString, "http://aircasting.org/api/sessions")
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
                exp.fulfill()
            })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 0.1)
    }
    
    func test_sendsCorrectJsonInBody() {
        setupWithCorrectDataReturned()
        let exp = expectation(description: "Will call correct endpoint")
        service
            .upload(session: .mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTAssertEqual(self.client.callHistory.count, 1)
                let request = self.client.callHistory.first!
                let json = try! JSONSerialization.jsonObject(with: request.httpBody!, options: .allowFragments) as! [String : Any]
                guard let gzippedBase64SessionJsonString = json["session"] as? String else {
                    XCTFail("Unexpected data format!")
                    return
                }
                guard let sessionJsonData = Data(base64Encoded: gzippedBase64SessionJsonString, options: .ignoreUnknownCharacters) else {
                    XCTFail("Session data is not Base64!")
                    return
                }
                guard sessionJsonData.isGzipped else {
                    XCTFail("Session data is not gzipped!")
                    return
                }
                guard let unzippedSessionJsonDatasessionJsonData = try? sessionJsonData.gunzipped() else {
                    XCTFail("Couldn't unzip session data!")
                    return
                }
                
                guard let sessionJson = try? JSONSerialization
                        .jsonObject(with: unzippedSessionJsonDatasessionJsonData, options: .allowFragments) as? [String : Any] else {
                    XCTFail("Couldnt read JSON object from unzipped session data!")
                    return
                }
                XCTAssertEqual(sessionJson["uuid"] as? String, "654321")
                // Note this also tests snake_case conversion:
                XCTAssertEqual(sessionJson["start_time"] as? String, "0001-01-01T01:24:00")
                XCTAssertEqual(sessionJson["contribute"] as? Bool, false)
                XCTAssertEqual(sessionJson["version"] as? Int, 1)
                let streams = sessionJson["streams"] as! [String : Any]
                XCTAssertEqual(streams.count, 1)
                let firstStream = streams["A sensor"] as! [String : Any]
                XCTAssertEqual(firstStream["id"] as! Int, 123456)
                exp.fulfill()
            })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 0.1)
    }
    
    // MARK: - Error handling
    
    func test_whenServerReturnsError_itErrorsToo() {
        setupWithAPICallError(DummyError())
        let exp = expectation(description: "It fails")
        service
            .upload(session: .mock())
            .sink(receiveCompletion: {
                guard case .failure = $0 else { return }
                exp.fulfill()
            }, receiveValue: {
                XCTFail("Unexpected value received: \($0)")
            }).store(in: &cancellables)
        wait(for: [exp], timeout: 0.1)
    }
    
    // MARK: - Fixture setup
    
    private func setupWithCorrectDataReturned() {
        client.requestTaskStub = { request, completion in
            let response: (data: Data, response: HTTPURLResponse) = (data: "OK".data(using: .utf8)!, response: .success())
            // We need the client to be asynchronous, see details in implementation file.
            DispatchQueue.global().async {
                completion(.success(response), request)
            }
        }
    }
    
    private func setupWithAPICallError(_ error: Error) {
        client.requestTaskStub = { request, completion in
            // We need the client to be asynchronous, see details in implementation file.
            DispatchQueue.global().async {
                completion(.failure(error), request)
            }
        }
    }
}

extension SessionsSynchronization.SessionUpstreamData {
    static func mock(uuid: SessionUUID = "654321") -> Self {
        .init(uuid: uuid,
              type: "Type",
              title: "Title",
              notes: [],
              tagList: "",
              startTime: .distantPast,
              endTime: .distantFuture,
              contribute: false,
              isIndoor: false,
              version: 1,
              streams: ["A sensor": .init(id: 123456,
                                          sensorName: "A sensor",
                                          sensorPackageName: "Package",
                                          unitName: "Unit",
                                          measurementType: "Type",
                                          measurementShortType: "ShortType",
                                          unitSymbol: "UnitSymbol",
                                          thresholdVeryLow: 10,
                                          thresholdLow: 20,
                                          thresholdMedium: 30,
                                          thresholdHigh: 40,
                                          thresholdVeryHigh: 50,
                                          deleted: false)],
              latitude: 50.0,
              longitude: 50.0,
              deleted: false)
    }
}
