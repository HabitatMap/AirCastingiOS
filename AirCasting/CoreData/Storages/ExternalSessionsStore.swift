// Created by Lunar on 26/04/2022.
//

import Foundation
import CoreData
import CoreLocation

protocol ExternalSessionsStore {
    func createExternalSession(session: ExternalSessionWithStreamsAndMeasurements, completion: @escaping (Result<Void, Error>) -> Void)
    func doesSessionExist(uuid: SessionUUID) -> Bool
    func deleteSession(uuid: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void)
}

struct DefaultExternalSessionsStore: ExternalSessionsStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createExternalSession(session: ExternalSessionWithStreamsAndMeasurements, completion: @escaping (Result<Void, Error>) -> Void) {
        enum CreatingExternalSessionError: Error {
            case sessionAlreadyExists
        }

        context.perform {
            do {
                guard (try? context.existingExternalSession(uuid: session.uuid)) == nil else {
                    throw CreatingExternalSessionError.sessionAlreadyExists
                }

                let sessionEntity = newSessionEntity()
                updateSessionsParams(sessionEntity, session: session)
                session.streams.forEach { stream in
                    addStream(stream, to: sessionEntity)
                }

                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func doesSessionExist(uuid: SessionUUID) -> Bool {
        var result: Bool = false
        context.performAndWait {
            result = (try? context.existingExternalSession(uuid: uuid)) != nil
        }
        return result
    }

    func deleteSession(uuid: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void) {
        context.perform {
            do {
                let session = try context.existingExternalSession(uuid: uuid)
                context.delete(session)
                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func addStream(_ stream: ExternalSessionWithStreamsAndMeasurements.Stream, to session: ExternalSessionEntity) {
        let measurementStream = MeasurementStreamEntity(context: context)
        updateMeasurementStreamParams(measurementStream, stream: stream)
        addMeasurements(stream.measurements, to: measurementStream)
        addThresholds(for: measurementStream)
        session.addToMeasurementStreams(measurementStream)
    }

    private func addMeasurements(_ measurements: [ExternalSessionWithStreamsAndMeasurements.Measurement], to stream: MeasurementStreamEntity) {
        measurements.forEach { measurement in
            let newMeasurement = MeasurementEntity(context: context)
            newMeasurement.location = CLLocationCoordinate2D(latitude: measurement.latitude, longitude: measurement.longitude)
            newMeasurement.time = measurement.time
            newMeasurement.value = measurement.value
            stream.addToMeasurements(newMeasurement)
        }
    }

    private func addThresholds(for stream: MeasurementStreamEntity) {
        guard !doesSensorThresholdExist(sensorName: stream.sensorName) else { return }
        guard let sensorName = stream.sensorName else {
            Log.error("Tried to create threshold for stream with no sensor name")
            return
        }

        createThreshold(sensorName: sensorName, thresholdValues: ThresholdsValue(veryLow: stream.thresholdVeryLow, low: stream.thresholdLow, medium: stream.thresholdMedium, high: stream.thresholdHigh, veryHigh: stream.thresholdVeryHigh))
    }

    private func doesSensorThresholdExist(sensorName: String?) -> Bool {
        (try? context.existingObject(sensorName: sensorName ?? "")) != nil
    }

    private func createThreshold(sensorName: String, thresholdValues: ThresholdsValue) {
        let threshold: SensorThreshold = SensorThreshold(context: context)
        threshold.sensorName = sensorName
        threshold.thresholdVeryLow = thresholdValues.veryLow
        threshold.thresholdLow = thresholdValues.low
        threshold.thresholdMedium = thresholdValues.medium
        threshold.thresholdHigh = thresholdValues.high
        threshold.thresholdVeryHigh = thresholdValues.veryHigh
    }

    private func newSessionEntity() -> ExternalSessionEntity {
        let sessionEntity = ExternalSessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.externalSession = sessionEntity
        return sessionEntity
    }

    private func updateSessionsParams(_ entity: ExternalSessionEntity, session: ExternalSessionWithStreamsAndMeasurements) {
        entity.uuid = session.uuid
        entity.name = session.name
        entity.latitude = session.latitude
        entity.longitude = session.longitude
        entity.startTime = session.startTime
        entity.endTime = session.endTime
        entity.provider = session.provider
    }

    private func updateMeasurementStreamParams(_ newStream: MeasurementStreamEntity, stream: ExternalSessionWithStreamsAndMeasurements.Stream) {
        newStream.id = MeasurementStreamID(exactly: stream.id)
        newStream.sensorName = stream.sensorName
        newStream.sensorPackageName = stream.sensorPackageName
        newStream.measurementType = stream.measurementType
        newStream.measurementShortType = stream.measurementShortType
        newStream.unitName = stream.unitName
        newStream.unitSymbol = stream.unitSymbol
        newStream.thresholdVeryLow = stream.thresholdsValues.veryLow
        newStream.thresholdLow = stream.thresholdsValues.low
        newStream.thresholdMedium = stream.thresholdsValues.medium
        newStream.thresholdHigh = stream.thresholdsValues.high
        newStream.thresholdVeryHigh = stream.thresholdsValues.veryHigh
        newStream.gotDeleted = false
    }
}
