// Created by Lunar on 18/04/2021.
//

import Foundation
import XCTest
import CoreData
@testable import AirCasting

final class UpdateSessionParamsServiceTests: ACTestCase {
    private static let sampleOutput = FixedSession.FixedMeasurementOutput(
        type: .fixed,
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
                    sensor_package_name: "Airbeam2:0018961070D6",
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


    private lazy var tested: UpdateSessionParamsService! = UpdateSessionParamsService()

    private lazy var databaseContext: NSManagedObjectContext! = {
        let container = NSPersistentContainer(name: "AirCasting")
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Faile to loadPersistentStores ")
            }
        }
        return container.viewContext
    }()

    override func tearDown() {
        tested = nil
        databaseContext = nil
        super.tearDown()
    }

    func testUpdateEmptySession() throws {
        let session = SessionEntity(context: databaseContext)
        let sampleOutput = Self.sampleOutput
        try tested.updateSessionsParams(session: session, output: sampleOutput)

        XCTAssertEqual(session.type, sampleOutput.type)
        XCTAssertEqual(session.uuid, sampleOutput.uuid)
        XCTAssertEqual(session.name, sampleOutput.title)
        XCTAssertEqual(session.tags, sampleOutput.tag_list)
        XCTAssertEqual(session.startTime, sampleOutput.start_time)
        XCTAssertEqual(session.endTime, sampleOutput.end_time)
        XCTAssertEqual(session.gotDeleted, sampleOutput.deleted ?? false)
        XCTAssertEqual(session.version, sampleOutput.version)
        let measurementStream = try XCTUnwrap(session.measurementStreams?.array as? [MeasurementStreamEntity])

        XCTAssertEqual(measurementStream.count, sampleOutput.streams.count)
        let modelMeasurementStream = sampleOutput.streams.values.sorted { $0.id < $1.id }
        try zip(measurementStream, modelMeasurementStream).forEach { databaseMeasurementStream, modelMeasurementStream in

            XCTAssertEqual(databaseMeasurementStream.gotDeleted, modelMeasurementStream.deleted ?? false)
            XCTAssertEqual(databaseMeasurementStream.measurementShortType, modelMeasurementStream.measurement_short_type)
            XCTAssertEqual(databaseMeasurementStream.measurementType, modelMeasurementStream.measurement_type)
            XCTAssertEqual(databaseMeasurementStream.sensorName, modelMeasurementStream.sensor_name)
            XCTAssertEqual(databaseMeasurementStream.sensorPackageName, modelMeasurementStream.sensor_package_name)
            XCTAssertEqual(databaseMeasurementStream.thresholdHigh, modelMeasurementStream.threshold_high)
            XCTAssertEqual(databaseMeasurementStream.thresholdLow, modelMeasurementStream.threshold_low)
            XCTAssertEqual(databaseMeasurementStream.thresholdMedium, modelMeasurementStream.threshold_medium)
            XCTAssertEqual(databaseMeasurementStream.thresholdVeryHigh, modelMeasurementStream.threshold_very_high)
            XCTAssertEqual(databaseMeasurementStream.thresholdVeryLow, modelMeasurementStream.threshold_very_low)
            XCTAssertEqual(databaseMeasurementStream.unitName, modelMeasurementStream.unit_name)
            XCTAssertEqual(databaseMeasurementStream.unitSymbol, modelMeasurementStream.unit_symbol)
            XCTAssertEqual(databaseMeasurementStream.id, modelMeasurementStream.id)

            let measurements = try XCTUnwrap(databaseMeasurementStream.measurements?.array as? [AirCasting.MeasurementEntity])
            XCTAssertEqual(measurements.count, modelMeasurementStream.measurements.count)
            try zip(measurements, modelMeasurementStream.measurements).forEach { databaseMeasurement, modelMeasurement in
                XCTAssertEqual(databaseMeasurement.value, modelMeasurement.measured_value)
                XCTAssertEqual(try XCTUnwrap(databaseMeasurement.location).latitude, modelMeasurement.latitude, accuracy: 0.01)
                XCTAssertEqual(try XCTUnwrap(databaseMeasurement.location).longitude, modelMeasurement.longitude, accuracy: 0.01)
                XCTAssertEqual(databaseMeasurement.time, modelMeasurement.time)
            }
        }
    }
}
