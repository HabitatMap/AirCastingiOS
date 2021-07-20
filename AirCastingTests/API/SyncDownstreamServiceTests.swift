// Created by Lunar on 19/06/2021.
//

import XCTest
import Combine
@testable import AirCasting

final class SyncDownstreamServiceTests: XCTestCase {
    private let client = APIClientMock()
    private let auth = RequestAuthorizationServiceMock()
    private let responseValidator = HTTPResponseValidatorMock()
    private lazy var service = SessionDownloadService(client: client, authorization: auth, responseValidator: responseValidator)
    private var cancellables: [AnyCancellable] = []
    
    override func tearDown() {
        super.tearDown()
        cancellables = []
    }
    
    func test_callsEndponitCorrectly() throws {
        setupWithCorrectDataReturned()
        
        let sessionUUID = SessionUUID.default
        try awaitPublisher(service.download(session: sessionUUID))
        
        XCTAssertEqual(self.client.callHistory.count, 1)
        let request = self.client.callHistory.first!
        XCTAssertEqual(request.url?.absoluteString, "http://aircasting.org/api/user/sessions/empty.json?uuid=\(sessionUUID.rawValue)")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields?["Accept"], "application/json")
    }
    
    func test_parsesDataCorrectly() throws {
        setupWithCorrectDataReturned()
        
        let session = try awaitPublisher(service.download(session: .random))
        
        XCTAssertEqual(session.id, 1704532)
        XCTAssertEqual(session.createdAt.timeIntervalSinceReferenceDate, 632226953)
        XCTAssertEqual(session.updatedAt.timeIntervalSinceReferenceDate, 632226953)
        XCTAssertEqual(session.userId, 5350)
        XCTAssertEqual(session.uuid, "aef5aac4-3a9e-43ac-b5ba-18e001d65162")
        XCTAssertEqual(session.urlToken, "2vtaf")
        XCTAssertEqual(session.title, "bxhxhd")
        XCTAssertEqual(session.contribute, true)
        XCTAssertEqual(session.startTime.timeIntervalSinceReferenceDate, 632230153)
        XCTAssertEqual(session.endTime?.timeIntervalSinceReferenceDate, 632230269)
        XCTAssertEqual(session.isIndoor, false)
        XCTAssertEqual(session.latitude!, 50.0443153, accuracy: 0.00001)
        XCTAssertEqual(session.longitude!, 19.9611183, accuracy: 0.00001)
        XCTAssertEqual(session.version, 0)
        XCTAssertEqual(session.tagList, "")
        XCTAssertEqual(session.type, "MobileSession")
        XCTAssertEqual(session.location?.absoluteString, "http://aircasting.habitatmap.org/s/2vtaf")
        XCTAssertEqual(session.streams.count, 1)
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.id, 2054733)
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.sensorName, "Phone Microphone-dB")
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.sensorPackageName, "Builtin")
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.unitName, "decibels")
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.measurementType, "Sound Level")
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.measurementShortType, "dB")
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.unitSymbol, "dB")
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.thresholdVeryLow, 20)
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.thresholdLow, 60)
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.thresholdMedium, 70)
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.thresholdHigh, 80)
        XCTAssertEqual(session.streams["Phone Microphone-dB"]?.thresholdVeryHigh, 100)
    }
    
    // MARK: - Error handling
    
    func test_whenServerReturnsError_finishesWithError() {
        setupWithAPICallError(DummyError())
        
        XCTAssertThrowsError(try awaitPublisher(service.download(session: .random)))
    }
    
    func test_whenServerReturnsMalformedData_finishesWithError() {
        setupWithMalformedData()
        
        XCTAssertThrowsError(try awaitPublisher(service.download(session: .random)))
    }
    
    // MARK: - Fixture setup
    
    private func setupWithCorrectDataReturned() {
        client.requestTaskStub = { request, completion in
            let response: (data: Data, response: HTTPURLResponse) = (data: self.validSessionResponseData, response: .success())
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
    
    private func setupWithMalformedData() {
        client.requestTaskStub = { request, completion in
            // 1KB of zeros
            let response: (data: Data, response: HTTPURLResponse) = (data: .init(count: 1024), response: .success())
            DispatchQueue.global().async {
                completion(.success(response), request)
            }
        }
    }
    
    // MARK: - JSON data
    
    let validSessionResponseData: Data =
        """
        {
            "id": 1704532,
            "created_at": "2021-01-13T11:35:53.000Z",
            "updated_at": "2021-01-13T11:35:53.000Z",
            "user_id": 5350,
            "uuid": "aef5aac4-3a9e-43ac-b5ba-18e001d65162",
            "url_token": "2vtaf",
            "title": "bxhxhd",
            "contribute": true,
            "data_type": null,
            "instrument": null,
            "start_time": "2021-01-13T12:29:13.000Z",
            "end_time": "2021-01-13T12:31:09.000Z",
            "measurements_count": null,
            "start_time_local": "2021-01-13T12:29:13.000Z",
            "end_time_local": "2021-01-13T12:31:09.000Z",
            "is_indoor": false,
            "latitude": 50.0443153,
            "longitude": 19.9611183,
            "last_measurement_at": null,
            "version": 0,
            "tag_list": "",
            "streams": {
                "Phone Microphone-dB": {
                    "id": 2054733,
                    "sensor_name": "Phone Microphone-dB",
                    "unit_name": "decibels",
                    "measurement_type": "Sound Level",
                    "measurement_short_type": "dB",
                    "unit_symbol": "dB",
                    "threshold_very_low": 20,
                    "threshold_low": 60,
                    "threshold_medium": 70,
                    "threshold_high": 80,
                    "threshold_very_high": 100,
                    "session_id": 1704532,
                    "sensor_package_name": "Builtin",
                    "measurements_count": 225,
                    "min_latitude": 50.0443014,
                    "max_latitude": 50.0443419,
                    "min_longitude": 19.9610574,
                    "max_longitude": 19.9611818,
                    "average_value": 28.6864,
                    "start_longitude": 19.9611183,
                    "start_latitude": 50.0443153,
                    "size": 225
                }
            },
            "type": "MobileSession",
            "location": "http://aircasting.habitatmap.org/s/2vtaf",
            "notes": []
        }
        """.data(using: .utf8)!
}

extension SessionUUID: TestDefaultProviding {
    static var `default`: SessionUUID {
        self.init(rawValue: UUID().uuidString)!
    }
}
