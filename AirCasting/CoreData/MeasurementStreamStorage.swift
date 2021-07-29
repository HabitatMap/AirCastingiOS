// Created by Lunar on 09/05/2021.
//

import CoreData
import CoreLocation
import Foundation

protocol MeasurementStreamStorage {
    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws
    func createMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID
    func createSession(_ session: Session) throws
    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws
    func updateSessionIfFollowing(_ sessionStatus: SessionFollowing, for sessionUUID: SessionUUID) throws
}

extension MeasurementStreamStorage {
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D? = nil, toStreamWithID id: MeasurementStreamLocalID) throws {
        try addMeasurement(Measurement(time: Date(), value: value, location: location), toStreamWithID: id)
    }
}

final class CoreDataMeasurementStreamStorage: MeasurementStreamStorage {
    enum Error: Swift.Error {
        case missingMeasurementStream
        case missingSensorName
    }

    private let persistenceController: PersistenceController
    private lazy var updateSessionParamsService = UpdateSessionParamsService()

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
        let context = persistenceController.editContext()
        let stream = try context.existingObject(with: id.id) as! MeasurementStreamEntity

        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.time
        newMeasurement.value = measurement.value
        stream.addToMeasurements(newMeasurement)

        let session = stream.session
        session?.endTime = newMeasurement.time
        session?.status = .RECORDING

        try context.save()
    }

    func createMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        let context = persistenceController.editContext()
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        return try createMeasurementStream(for: sessionEntity, context: context, stream)
    }

    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
        let context = persistenceController.editContext()
        let sessionEntity = SessionEntity(context: context)
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        return try createMeasurementStream(for: sessionEntity, context: context, stream)
    }

    private func createMeasurementStream(for session: SessionEntity, context: NSManagedObjectContext, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
        let newStream = MeasurementStreamEntity(context: context)
        newStream.sensorName = stream.sensorName
        newStream.sensorPackageName = stream.sensorPackageName
        newStream.measurementType = stream.measurementType
        newStream.measurementShortType = stream.measurementShortType
        newStream.unitName = stream.unitName
        newStream.unitSymbol = stream.unitSymbol
        newStream.thresholdVeryLow = stream.thresholdVeryLow
        newStream.thresholdLow = stream.thresholdLow
        newStream.thresholdMedium = stream.thresholdMedium
        newStream.thresholdHigh = stream.thresholdHigh
        newStream.thresholdVeryHigh = stream.thresholdVeryHigh
        newStream.gotDeleted = false

        session.addToMeasurementStreams(newStream)

        guard let sensorName = stream.sensorName else {
            throw Error.missingSensorName
        }
        let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: sensorName)
        if existingThreshold == nil {
            let threshold: SensorThreshold = try context.newOrExisting(sensorName: sensorName)
            threshold.thresholdVeryLow = stream.thresholdVeryLow
            threshold.thresholdLow = stream.thresholdLow
            threshold.thresholdMedium = stream.thresholdMedium
            threshold.thresholdHigh = stream.thresholdHigh
            threshold.thresholdVeryHigh = stream.thresholdVeryHigh
        }
        try context.save()
        return newStream.localID
    }

    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        let context = persistenceController.editContext()
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = sessionStatus
        try context.save()
    }

    func updateSessionIfFollowing(_ sessionFollowing: SessionFollowing, for sessionUUID: SessionUUID) throws {
        let context = persistenceController.editContext()
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        let copySession = sessionEntity
        if sessionFollowing.rawValue == 1 {
            sessionEntity.followedAt = Date()
            sessionEntity.type = .following
            copySession.type = .fixed
        } else {
            sessionEntity.followedAt = nil
            sessionEntity.type = .fixed
        }
        context.performAndWait {
            do {
                try context.save()
            } catch {
                Log.info("Error when saving changes in session")
            }
        }
    }

    func createSession(_ session: Session) throws {
        let context = persistenceController.editContext()
        let sessionEntity = SessionEntity(context: context)
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        try context.save()
    }
}

#if DEBUG
/// Only to be used for swiftui previews
final class PreviewMeasurementStreamStorage: MeasurementStreamStorage {
    func updateSessionIfFollowing(_ sessionStatus: SessionFollowing, for sessionUUID: SessionUUID) throws {}

    func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
        print("Nothing happened for \(measurement)")
    }

    func createMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        fatalError()
    }

    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
        fatalError()
    }

    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        print("Nothing happened for \(sessionStatus) \(sessionUUID)")
    }

    func createSession(_ session: Session) throws {
        print("Nothing happened for \(session)")
    }
}
#endif
