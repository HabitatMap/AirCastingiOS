// Created by Lunar on 19/06/2021.
//

import XCTest
import Combine
import Gzip
@testable import AirCasting

final class SyncUpstreamServiceTests: XCTestCase {
    let client = APIClientMock()
    let auth = RequestAuthorizationServiceMock()
    let responseValidator = HTTPResponseValidatorMock()
    lazy var service = SessionUploadService(client: client, authorization: auth, responseValidator: responseValidator)
    private var cancellables: [AnyCancellable] = []
    
    override func tearDown() {
        super.tearDown()
        cancellables = []
    }
    
    func test_callsEndponitCorrectly() throws {
        setupWithCorrectDataReturned()
        
        try awaitPublisher(service.upload(session: .mock()))
        
        XCTAssertEqual(self.client.callHistory.count, 1)
        let request = self.client.callHistory.first!
        XCTAssertEqual(request.url?.absoluteString, "http://aircasting.org/api/sessions")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
    }
    
    func test_sendsCorrectJsonInBody() throws {
        setupWithCorrectDataReturned()
        
        try awaitPublisher(service.upload(session: .mock()))
        
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
        XCTAssertEqual(sessionJson["start_time"] as? String, "0001-01-01T01:24:00.000Z")
        XCTAssertEqual(sessionJson["contribute"] as? Bool, false)
        XCTAssertEqual(sessionJson["version"] as? Int, 1)
        let streams = sessionJson["streams"] as! [String : Any]
        XCTAssertEqual(streams.count, 1)
        let sensorStream = streams["A sensor"] as! [String : Any]
        XCTAssertEqual(sensorStream["unit_name"] as? String, "Unit")
        XCTAssertEqual(sensorStream["threshold_very_low"] as? Int, 10)
        XCTAssertEqual(sensorStream["threshold_very_high"] as? Int, 50)
        XCTAssertEqual(sensorStream["unit_symbol"] as? String, "UnitSymbol")
        XCTAssertEqual(sensorStream["measurement_short_type"] as? String, "ShortType")
        XCTAssertEqual(sensorStream["threshold_medium"] as? Int, 30)
        XCTAssertEqual(sensorStream["deleted"] as? Bool, false)
        XCTAssertEqual(sensorStream["threshold_high"] as? Int, 40)
        XCTAssertEqual(sensorStream["threshold_low"] as? Int, 20)
        XCTAssertEqual(sensorStream["measurement_type"] as? String, "Type")
        XCTAssertEqual(sensorStream["sensor_name"] as? String, "A sensor")
        XCTAssertEqual(sensorStream["sensor_package_name"] as? String, "Package")
        let measuremnets = sensorStream["measurements"] as! [[String : Any]]
        XCTAssertEqual(measuremnets.count, 1)
        XCTAssertEqual(measuremnets.first?["value"] as! Double, 12.0, accuracy: 0.001)
        XCTAssertEqual(measuremnets.first?["longitude"] as! Double, 50.12, accuracy: 0.001)
        XCTAssertEqual(measuremnets.first?["time"] as? String, "2001-01-01T01:02:30.000Z")
        XCTAssertEqual(measuremnets.first?["latitude"] as! Double, 51.01, accuracy: 0.001)
        XCTAssertEqual(measuremnets.first?["miliseconds"] as? Int, 87)
    }
    
    // MARK: - Error handling
    
    func test_whenServerReturnsError_itErrorsToo() {
        setupWithAPICallError(DummyError())
        
        XCTAssertThrowsError(try awaitPublisher(service.upload(session: .mock())))
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
              streams: ["A sensor": .init(sensorName: "A sensor",
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
                                          deleted: false,
                                          measurements: [
                                            .mock()
                                          ])],
              latitude: 50.0,
              longitude: 50.0,
              deleted: false)
    }
}

extension SessionsSynchronization.MeasurementUpstreamData {
    static func mock() -> Self {
        .init(value: 12.00, miliseconds: 87, latitude: 51.01, longitude: 50.12, time: Date(timeIntervalSinceReferenceDate: 150))
    }
}
