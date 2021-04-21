//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import XCTest
import Combine
@testable import AirCasting

final class AuthorisationServiceMock: RequestAuthorisationService {
    var authoriseStub: ((_ request: URLRequest) throws -> URLRequest)

    init(authoriseStub: @escaping (_ request: URLRequest) throws -> URLRequest = { return $0 }) {
        self.authoriseStub = authoriseStub
    }

    @discardableResult
    func authorise(request: inout URLRequest) throws -> URLRequest {
        try authoriseStub(request)
    }
}

final class FixedSessionTests: XCTestCase {
    private lazy var apiClientMock: APIClientMock! = APIClientMock()
    private lazy var authorisationServiceMock: AuthorisationServiceMock! = AuthorisationServiceMock()
    private lazy var tested: FixedSessionAPIService! = FixedSessionAPIService(authorisationService: authorisationServiceMock, apiClient: apiClientMock)

    override func tearDown() {
        self.apiClientMock = nil
        self.authorisationServiceMock = nil
        self.tested = nil
        super.tearDown()
    }

    func testTimeout() throws {
        apiClientMock.failing(with: URLError(.timedOut))

        let result = try awaitPublisherResult(tested.getFixedMeasurement(uuid: SessionUUID(), lastSync: Date()))

        switch result {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(URLError.timedOut):
            print("Retuned valid error")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testRequestCreation() throws {
        var receivedRequest: URLRequest?
        apiClientMock.fetchPublisherStub = {
            receivedRequest = $0
            return .failure(URLError(.timedOut))
        }

        _ = tested.getFixedMeasurement(uuid: SessionUUID(uuidString: "DCEAE4A1-DD48-44D7-A0C1-C5525F81C6B2")!, lastSync: Date(timeIntervalSinceReferenceDate: 1991037271))

        let request = try XCTUnwrap(receivedRequest)
        XCTAssertEqual(request.url, URL(string:"http://aircasting.org/api/realtime/sync_measurements.json?uuid=DCEAE4A1-DD48-44D7-A0C1-C5525F81C6B2&last_measurement_sync=2064-02-04T09:54:31.000Z")!)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields, ["Accept": "application/json", "Content-Type": "application/json"])
    }

    func testRequestCreationFailedWhenAuthorizationFails() throws {
        struct MockError: Swift.Error {}

        authorisationServiceMock.authoriseStub = { _ in
            throw MockError()
        }

        let result = try awaitPublisherResult(tested.getFixedMeasurement(uuid: SessionUUID(), lastSync: Date()))

        switch result {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(URLError.userAuthenticationRequired):
            print("Retuned valid error \(result)")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testInvalidResponse() throws {
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        apiClientMock.returning((data: Data(#"{ "error": "some invalid message" }"#.utf8), response: response))

        let result = try awaitPublisherResult(tested.getFixedMeasurement(uuid: SessionUUID(), lastSync: Date()))

        switch result {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(URLError.badServerResponse):
            print("Retuned valid error \(result)")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testSuccessfulSampleFileResponse() throws {
        let url = Bundle(for: Self.self).url(forResource: "SampleFixedSession", withExtension: "json")!
        let data = try Data(contentsOf: url)
        apiClientMock.returning((data: data, response: .success()))

        let response = try awaitPublisherResult(tested.getFixedMeasurement(uuid: SessionUUID(), lastSync: Date())).get()

        let expectedResponse = FixedSession.FixedMeasurementOutput(
            type: .FIXED,
            uuid: SessionUUID(uuidString: "51dd1e15-0af6-4810-bacd-11e061ac9d1d")!,
            title: "hetmafixab",
            tag_list: "",
            start_time: Date(timeIntervalSinceReferenceDate: 621782366),
            end_time: Date(timeIntervalSinceReferenceDate: 621782618),
            deleted: nil,
            version: 0,
            streams: ["AirBeam2-F": FixedSession.StreamOutput(
                        id: 2015180,
                        sensor_name: "AirBeam2-F",
                        sensor_package_name: "Airbeam2-0018961070D6",
                        measurement_type: "Temperature",
                        measurement_short_type: "F",
                        unit_name: "fahrenheit",
                        unit_symbol: "F",
                        threshold_very_low: 15,
                        threshold_low: 45,
                        threshold_medium: 75,
                        threshold_high: 105,
                        threshold_very_high: 135,
                        deleted: nil,
                        measurements: [FixedSession.MeasurementOutput(
                                        id: 1991037271,
                                        value: 88.0,
                                        latitude: 200.0,
                                        longitude: 200.0,
                                        time: Date(timeIntervalSinceReferenceDate : 621782378),
                                        stream_id: 2015180,
                                        milliseconds: 0.0,
                                        measured_value: 88.0),
                                       FixedSession.MeasurementOutput(
                                        id: 1991037396,
                                        value: 89.0,
                                        latitude: 200.0,
                                        longitude: 200.0,
                                        time: Date(timeIntervalSinceReferenceDate : 621782438),
                                        stream_id: 2015180,
                                        milliseconds: 0.0,
                                        measured_value: 89.0),
                                       FixedSession.MeasurementOutput(
                                        id: 1991037522,
                                        value: 90.0,
                                        latitude: 200.0,
                                        longitude: 200.0,
                                        time: Date(timeIntervalSinceReferenceDate : 621782498),
                                        stream_id: 2015180,
                                        milliseconds: 0.0,
                                        measured_value: 90.0),
                                       FixedSession.MeasurementOutput(
                                        id: 1991037648,
                                        value: 91.0,
                                        latitude: 200.0,
                                        longitude: 200.0,
                                        time: Date(timeIntervalSinceReferenceDate : 621782558),
                                        stream_id: 2015180,
                                        milliseconds: 0.0,
                                        measured_value: 91.0),
                                       FixedSession.MeasurementOutput(
                                        id: 1991037774,
                                        value: 91.0,
                                        latitude: 200.0,
                                        longitude: 200.0,
                                        time: Date(timeIntervalSinceReferenceDate : 621782618),
                                        stream_id: 2015180,
                                        milliseconds: 0.0,
                                        measured_value: 91.0)])
            ])
        XCTAssertEqual(expectedResponse, response)
    }
}
