// Created by Lunar on 19/04/2021.
//

import XCTest
@testable import AirCasting

final class CreateSessionAPIServiceTests: APIServiceTestCase {
    private lazy var tested: CreateSessionAPIService = CreateSessionAPIService()

    private lazy var sampleInput = CreateSessionApi.Input.mock()

    func testTimeout() throws {
        client.failing(with: URLError(.timedOut))

        var result: Result<CreateSessionApi.Output, Error>?
        tested.createEmptyFixedWifiSession(input: sampleInput) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(URLError.timedOut):
            print("Retuned valid error")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testRequestCreation() throws {
        struct APIInput: Codable, Equatable {
            let session: String
            let compression: Bool
        }
        var receivedRequest: URLRequest?
        client.requestTaskStub = { request, completion in
            receivedRequest = request
            completion(.failure(URLError(.timedOut)), request)
        }
        tested.createEmptyFixedWifiSession(input: sampleInput) { _ in }

        let request = try XCTUnwrap(receivedRequest)
        let httpBody = try XCTUnwrap(request.httpBody)
        XCTAssertEqual(request.url, URL(string:"http://aircasting.org/api/realtime/sessions.json")!)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.allHTTPHeaderFields, ["Accept": "application/json", "Content-Type": "application/json"])

        let encoder: JSONEncoder = JSONEncoder()
        let formatter = DateFormatters.CreateSessionAPIService.encoderDateFormatter
        encoder.dateEncodingStrategy = .formatted(formatter)

        let inputJSONData = try encoder.encode(sampleInput.session)
        let gzippedData = try inputJSONData.gzipped()
        let sessionBase64String = gzippedData.base64EncodedString(options: [.lineLength76Characters, .endLineWithLineFeed])

        let apiInput = APIInput(session: sessionBase64String, compression: sampleInput.compression)
        XCTAssertEqual(try JSONDecoder().decode(APIInput.self, from: httpBody), apiInput)
    }

    func testRequestCreationFailedWhenAuthorizationFails() throws {
        struct MockError: Swift.Error {}

        authorization.authoriseStub = { _ in
            throw MockError()
        }

        var result: Result<CreateSessionApi.Output, Error>?
        tested.createEmptyFixedWifiSession(input: sampleInput) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(let error) where error is MockError:
            print("Retuned valid error \(String(describing: result))")
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testInvalidResponse() throws {
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        client.returning((data: Data(#"{ "error": "some invalid message" }"#.utf8), response: response))

        let errorContent = "ASD"
        validator.stubError = DummyError(errorData: "ASD")
        
        var result: Result<CreateSessionApi.Output, Error>?
        tested.createEmptyFixedWifiSession(input: sampleInput) {
            result = $0
        }

        switch try XCTUnwrap(result) {
        case .success(let response):
            XCTFail("Should fail but returned success type \(response)")
        case .failure(let error as DummyError):
            XCTAssertEqual(error.errorData, errorContent)
        case .failure(let error):
            XCTFail("Failed with a unexpected error type \(error)")
        }
    }

    func testSuccessfulCreationResponse() throws {
        let location = UUID().uuidString
        let data = Data("{\"location\": \"\(location)\"}".utf8)
        client.returning((data: data, response: .success()))

        var result: Result<CreateSessionApi.Output, Error>?
        tested.createEmptyFixedWifiSession(input: sampleInput) {
            result = $0
        }

        let expectedResponse = CreateSessionApi.Output(location: location)
        XCTAssertEqual(expectedResponse, try XCTUnwrap(result).get())
    }
}


extension CreateSessionApi.Input {
    static func mock() -> CreateSessionApi.Input {
        var streams: [String: CreateSessionApi.MeasurementStreamParams] = [:]
        Array(0...Int.random(in: 1...10)).forEach {
            streams["\($0)"] = CreateSessionApi.MeasurementStreamParams.mock()
        }
        return CreateSessionApi.Input(session: CreateSessionApi.SessionParams(uuid: SessionUUID(),
                                                                       type: [SessionType.fixed, .mobile].randomElement()!,
                                                                       title: UUID().uuidString,
                                                                       tag_list: UUID().uuidString,
                                                                       start_time: Date(),
                                                                       end_time: Date(),
                                                                       contribute: .random(),
                                                                       is_indoor: .random(),
                                                                       notes: [],
                                                                       version: .random(in: -999...999),
                                                                       streams: streams,
                                                                       latitude: .random(in: -90...90),
                                                                       longitude: .random(in: -180...180)),
                                      compression: true)
    }
}

extension CreateSessionApi.MeasurementStreamParams {
    static func mock() -> CreateSessionApi.MeasurementStreamParams {
        let measurements = Array(0...Int.random(in: 1...10)).map({ _ in CreateSessionApi.MeasurementParams.mock() })
        return CreateSessionApi.MeasurementStreamParams(deleted: .random(),
                                                 sensor_package_name: UUID().uuidString,
                                                 sensor_name: UUID().uuidString,
                                                 measurement_type: UUID().uuidString,
                                                 measurement_short_type: UUID().uuidString,
                                                 unit_name: UUID().uuidString,
                                                 unit_symbol: UUID().uuidString,
                                                 threshold_very_high: .random(in: -999...999),
                                                 threshold_high: .random(in: -999...999),
                                                 threshold_medium: .random(in: -999...999),
                                                 threshold_low: .random(in: -999...999),
                                                 threshold_very_low: .random(in: -999...999),
                                                 measurements: measurements)
    }
}

extension CreateSessionApi.MeasurementParams {
    static func mock() -> CreateSessionApi.MeasurementParams {
        CreateSessionApi.MeasurementParams(longitude: .random(in: -90...90),
                                           latitude: .random(in: -180...180),
                                           milliseconds: .random(in: -90...90),
                                           time: Date(),
                                           value: .random(in: -999...999))
    }
}
