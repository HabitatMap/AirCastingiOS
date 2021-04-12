//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import XCTest
import Combine
@testable import AirCasting

final class FixedSessionTests: XCTestCase {
    private lazy var apiClientMock: APIClientMock! = APIClientMock()
    private lazy var tested: FixedSessionService! = FixedSessionService(apiClient: apiClientMock)

    override func tearDown() {
        self.apiClientMock = nil
        self.tested = nil
        super.tearDown()
    }

    func testTimeout() throws {
        apiClientMock.failing(with: URLError(.timedOut))

        let result = try awaitPublisherResult(tested.getFixedMeasurement(uuid: UUID(), lastSync: Date()))

        switch result {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(URLError.timedOut):
            print("Retuned valid error")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testInvalidResponse() throws {
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        apiClientMock.returning((data: Data(#"{ "error": "some invalid message" }"#.utf8), response: response))

        let result = try awaitPublisherResult(tested.getFixedMeasurement(uuid: UUID(), lastSync: Date()))

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

        let response = try awaitPublisherResult(tested.getFixedMeasurement(uuid: UUID(), lastSync: Date())).get()

        let expectedResponse = FixedSession.FixedMeasurementOutput(id: 1692523,
                                                                   type: .FIXED,
                                                                   uuid: UUID(uuidString: "51dd1e15-0af6-4810-bacd-11e061ac9d1d")!,
                                                                   title: "hetmafixab",
                                                                   tag_list: "",
                                                                   start_time: Date(timeIntervalSinceReferenceDate: 621782366),
                                                                   end_time: Date(timeIntervalSinceReferenceDate: 621782618),
                                                                   deleted: nil,
                                                                   version: 0,
                                                                   streams: ["AirBeam2-F": FixedSession.StreamOutput(id: 2015180,
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
                                                                                                                     measurements: [FixedSession.MeasurementOutput(id: 1991037271,
                                                                                                                                                                   value: 88.0,
                                                                                                                                                                   latitude: 200.0,
                                                                                                                                                                   longitude: 200.0,
                                                                                                                                                                   time: Date(timeIntervalSinceReferenceDate : 621782378),
                                                                                                                                                                   stream_id: 2015180,
                                                                                                                                                                   milliseconds: 0.0,
                                                                                                                                                                   measured_value: 88.0),
                                                                                                                                    FixedSession.MeasurementOutput(id: 1991037396,
                                                                                                                                                                   value: 89.0,
                                                                                                                                                                   latitude: 200.0,
                                                                                                                                                                   longitude: 200.0,
                                                                                                                                                                   time: Date(timeIntervalSinceReferenceDate : 621782438),
                                                                                                                                                                   stream_id: 2015180,
                                                                                                                                                                   milliseconds: 0.0,
                                                                                                                                                                   measured_value: 89.0),
                                                                                                                                    FixedSession.MeasurementOutput(id: 1991037522,
                                                                                                                                                                   value: 90.0,
                                                                                                                                                                   latitude: 200.0,
                                                                                                                                                                   longitude: 200.0,
                                                                                                                                                                   time: Date(timeIntervalSinceReferenceDate : 621782498),
                                                                                                                                                                   stream_id: 2015180,
                                                                                                                                                                   milliseconds: 0.0,
                                                                                                                                                                   measured_value: 90.0),
                                                                                                                                    FixedSession.MeasurementOutput(id: 1991037648,
                                                                                                                                                                   value: 91.0,
                                                                                                                                                                   latitude: 200.0,
                                                                                                                                                                   longitude: 200.0,
                                                                                                                                                                   time: Date(timeIntervalSinceReferenceDate : 621782558),
                                                                                                                                                                   stream_id: 2015180,
                                                                                                                                                                   milliseconds: 0.0,
                                                                                                                                                                   measured_value: 91.0),
                                                                                                                                    FixedSession.MeasurementOutput(id: 1991037774,
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
